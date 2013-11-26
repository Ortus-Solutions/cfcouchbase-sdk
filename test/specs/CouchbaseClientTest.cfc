/**
********************************************************************************
* Copyright Since 2005 Ortus Solutions, Corp
* www.coldbox.org | www.luismajano.com | www.ortussolutions.com | www.gocontentbox.org
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALING
* IN THE SOFTWARE.
********************************************************************************
*/
component{
	
/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		couchbase = new cfcouchbase.CouchbaseClient();
	}

	function afterAll(){
		couchbase.shutdown( 10 );
	}

/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "Couchbase Client", function(){

			xit( "can flush docs", function(){
				var future = couchbase.flush();
				future.get();
				expect( couchbase.getStats( "vb_active_curr_items" ) ).toBe( 0 );
			});

			it( "can touch an expiration time", function(){
				couchbase.set( id="touch-test", value="value", timeout=10 );
				var future = couchbase.touch( id="touch-test", timeout=0 );
				expect(	future.get() ).toBeTrue();
			});

			/**************************************************************/
			/**************** construction ********************************/
			/**************************************************************/
			describe( "can be constructed ", function(){
				
				it( "with vanilla settings", function(){
					expect(	couchbase ).toBeComponent();
				});

				it( "with config struct literal", function(){
					expect(	new cfcouchbase.CouchbaseClient( config={servers="http://127.0.0.1:8091", bucketname="default"} ) ).toBeComponent();
				});

				it( "with config object instance", function(){
					var config = new cfcouchbase.config.CouchbaseConfig( bucketname="default", viewTimeout="1000" );
					expect(	new cfcouchbase.CouchbaseClient( config=config ) ).toBeComponent();
				});

				it( "with config object path", function(){
					expect(	new cfcouchbase.CouchbaseClient( config="test.resources.Config" ) ).toBeComponent();
				});

				it( "with simple config object", function(){
					var config = new test.resources.SimpleConfig();
					var cbClient = new cfcouchbase.CouchbaseClient( config=config );
					expect(	cbClient ).toBeComponent();
					expect(	cbClient.getCouchbaseConfig().getDefaultTimeout() ).toBe( 30 );
				});
			
			});

			/**************************************************************/
			/**************** set operations ******************************/
			/**************************************************************/
			describe( "set operations", function(){
				it( "with just ID and value", function(){
					var future = couchbase.set( ID="unittest", value="hello" );
					future.get();
					expect(	future.getStatus().isSuccess() ).toBeTrue();
				});	

				it( "with json data", function(){
					var data = serializeJSON( { "name"="Lui", "awesome"=true, "when"=now(), "children" = [1,2] } );
					var future = couchbase.set( ID="unittest-json", value=data );
					future.get();	
					expect(	future.getStatus().isSuccess() ).toBeTrue();
				});	

				it( "can decrement values", function(){
					var future = couchbase.set( ID="unit-decrement", value="10" );
					future.get();	
					var result = couchbase.decr( "unit-decrement", 1 );
					expect(	result ).toBe( 9 );
				});	

				it( "can decrement values asynchronously", function(){
					var future = couchbase.set( ID="unit-decrement", value="10" );
					future.get();	
					var result = couchbase.asyncDecr( "unit-decrement", 1 );
					expect(	result.get() ).toBe( 9 );
				});	

				it( "can increment values", function(){
					var future = couchbase.set( ID="unit-increment", value="10" );
					future.get();	
					var result = couchbase.incr( "unit-increment", 10 );
					expect(	result ).toBe( 20 );
				});	

				it( "can increment values asynchronously", function(){
					var future = couchbase.set( ID="unit-increment", value="10" );
					future.get();	
					var result = couchbase.asyncIncr( "unit-increment", 10 );
					expect(	result.get() ).toBe( 20 );
				});
				
				it( "will set multiple documents", function(){
					var data = {
						"id1"="value1",
						"id2"="value2",
						"id3"="value3"
					};
					var futures = couchbase.setMulti( data=data, timeout=1 );
					
					expect(	futures ).toBeStruct();
					
					expect(	futures ).toHaveKey( "id1" );
					expect(	futures ).toHaveKey( "id2" );
					expect(	futures ).toHaveKey( "id3" );
					
					// toBeInstanceOf() expectation doesn't work on natively created Java classes
					expect(	futures.id1.getClass().getName() ).toBe( "net.spy.memcached.internal.OperationFuture" );
					expect(	futures.id2.getClass().getName() ).toBe( "net.spy.memcached.internal.OperationFuture" );
					expect(	futures.id3.getClass().getName() ).toBe( "net.spy.memcached.internal.OperationFuture" );
					
					expect(	couchbase.get( "id1" ) ).toBe( "value1" );
					expect(	couchbase.get( "id2" ) ).toBe( "value2" );
					expect(	couchbase.get( "id3" ) ).toBe( "value3" );
										
				});
				
								
				it( "with CAS value that hasn't changed", function(){
					couchbase.set( ID="unittest", value="hello" ).get();
					var getResult = couchbase.getWithCAS( ID="unittest" );
					var setResult = couchbase.setWithCAS( ID="unittest", CAS=getResult.CAS, value="New Value" );
										
					expect(	setResult ).toBeStruct();
					expect(	setResult ).toHaveKey( "status" );
					expect(	setResult ).toHaveKey( "detail" );
					expect(	setResult.status ).toBe( true );
					expect(	setResult.detail ).toBe( "SUCCESS" );
				});	
								
				it( "with CAS value that is out-of-date", function(){
					couchbase.set( ID="unittest", value="hello" ).get();
					var getResult = couchbase.getWithCAS( ID="unittest" );
					couchbase.set( ID="unittest", value="a new value" ).get();					
					var setResult = couchbase.setWithCAS( ID="unittest", CAS=getResult.CAS, value="New Value" );

					expect(	setResult ).toBeStruct();
					expect(	setResult ).toHaveKey( "status" );
					expect(	setResult ).toHaveKey( "detail" );
					expect(	setResult.status ).toBe( false );
					expect(	setResult.detail ).toBe( "CAS_CHANGED" );
				});		
								
				it( "with CAS value and key that doesn't exist", function(){
					var setResult = couchbase.setWithCAS( ID=createUUID(), CAS=123456789, value="New Value" );
										
					expect(	setResult ).toBeStruct();
					expect(	setResult ).toHaveKey( "status" );
					expect(	setResult ).toHaveKey( "detail" );
					expect(	setResult.status ).toBe( false );
					expect(	setResult.detail ).toBe( "NOT_FOUND" );
				});	
								
			});


			/**************************************************************/
			/**************** replace *************************************/
			/**************************************************************/
			describe( "replace operations", function(){
				it( "will replace a document", function(){
					var future = couchbase.set( ID="replaceMe", value="whatever", timeout=1 );
					future.get();
					var future = couchbase.replace( ID="replaceMe", value="new value", timeout=1 );
					
					expect(	future.get() ).toBe( true );
					
					var future = couchbase.replace( ID=createUUID(), value="Not gonna' exist", timeout=1 );
																				
					expect(	future.get() ).toBe( false );
				});			
			});

			/**************************************************************/
			/**************** get operations ******************************/
			/**************************************************************/
			describe( "get operations", function(){
				it( "of a valid object", function(){
					var data = now();
					var future = couchbase.set( ID="unittest", value=data );
					future.get();	
					expect(	couchbase.get( "unittest" ) ).toBe( data );
				});		

				it( "of an invalid object", function(){
					expect(	couchbase.get( "Nothing123" ) ).toBeNull();
				});
				
				it( "of a valid object with CAS", function(){
					var data = now();
					var future = couchbase.set( ID="unittest", value=data );
					future.get();
					var result = couchbase.getWithCAS( "unittest" );
					 
					expect(	result ).toBeStruct(); 
					expect(	result ).toHaveKey( "CAS" );
					expect(	result ).toHaveKey( "value" );
					expect(	result.CAS ).toBeNumeric(); 
					expect(	result.value ).toBe( data );
					
				});		

				it( "of an invalid object with CAS", function(){
					expect(	couchbase.get( "Nothing123" ) ).toBeNull();
				});
				
				it( "of a valid object with touch", function(){
					var data = now();
					// Set with 5 minute timeout
					var future = couchbase.set( ID="unittest", value=data, timeout=5 ).get();
					var stats = couchbase.getDocStats( "unittest" ).get();
					var original_exptime = stats.key_exptime;
					
					// Touch with 10 minute timeout
					var result = couchbase.getAndTouch( "unittest", 10 );
					 
					expect(	result ).toBeStruct(); 
					expect(	result ).toHaveKey( "CAS" );
					expect(	result ).toHaveKey( "value" );
					expect(	result.CAS ).toBeNumeric(); 
					expect(	result.value ).toBe( data );
										
					var stats = couchbase.getDocStats( "unittest" ).get();
					
					// The timeout should now be 5 minutes farther in the future
					expect(	stats.key_exptime > original_exptime ).toBeTrue();
					
				});		

				it( "of an invalid object with touch", function(){
					expect(	couchbase.getAndTouch( "Nothing123", 10 ) ).toBeNull();
				});

				it( "with case-insensitive IDs", function(){
					var data = now();
					couchbase.set( ID="myid ", value=data ).get();
					expect(	couchbase.get( "MYID" ) ).toBe( data );
				});
				

				it( "with multiple IDs", function(){
					couchbase.set( ID="ID1", value="value1" ).get();
					couchbase.set( ID="ID2", value="value2" ).get();
					couchbase.set( ID="ID3", value="value3" ).get();
					
					var result = couchbase.getMulti( ["ID1","ID2","ID3","not_existant"] );
					
					expect(	result ).toBeStruct();
					
					expect(	result ).toHaveKey( "id1" );
					expect(	result ).toHaveKey( "id2" );
					expect(	result ).toHaveKey( "id3" );
					
					expect(	result.id1 ).toBe( "value1" );
					expect(	result.id2 ).toBe( "value2" );
					expect(	result.id3 ).toBe( "value3" );
					
					expect(	result ).notToHaveKey( "not_existant" );
					 
					
				});
				
			});


			/**************************************************************/
			/**************** add operations ******************************/
			/**************************************************************/
			describe( "add operations", function(){
				it( "will only add once", function(){
					var data = now();
					var randID = createUUID();
					var future = couchbase.add( ID=randID, value=data, timeout=1 );
					
					expect(	future.get() ).toBe( true );
					expect(	couchbase.get( randID ) ).toBe( data );
					
					var future = couchbase.add( ID=randID, value=data, timeout=1 );
										
					expect(	future.get() ).toBe( false );
				});			
			});

			/**************************************************************/
			/**************** delete operations ***************************/
			/**************************************************************/
			describe( "delete operations", function(){
			
				it( "of an invalid document", function(){
					var future = couchbase.delete( id="invalid-doc" );
					expect(	future.get() ).toBeFalse();
				});

				it( "of a valid document", function(){
					var future = couchbase.set( ID="unittest", value="hello" );
					future.get();	
					var future = couchbase.delete( id="unittest" );
					expect(	future.get() ).toBeTrue();
				});

				it( "of multiple documents", function(){
					var data = { "data1" = "null", "data2"= "luis majano" };
					var futures = couchbase.setMulti( data=data );
					for( var key in futures ){ futures[ key ].get(); }

					var futures = couchbase.delete( id=[ "data1", "data2" ] );
					for( var key in futures ){
						expect(	futures[ key ].get() ).toBeTrue();
					}
				});
			
			});

			/**************************************************************/
			/**************** stats operations ****************************/
			/**************************************************************/
			describe( "stats operations", function(){
			
				it( "can get global stats", function(){
					var stats = couchbase.getStats();
					expect( stats ).toBeStruct();
					expect( couchbase.getStats( "vb_active_curr_items" ) ).toBeNumeric();
				});

				it( "can get doc stats", function(){
					var future = couchbase.set( ID="unittest", value="hello", timeout=200 );
					future.get();
					var future = couchbase.getDocStats( "unittest" );
					expect(	future.get() ).toBeStruct();
				});

				it( "can get multiple doc stats", function(){
					var data = { "data1" = "null", "data2"= "luis majano" };
					var futures = couchbase.setMulti( data=data );
					for( var key in futures ){ futures[ key ].get(); }

					var futures = couchbase.getDocStats( id=[ "data1", "data2" ] );
					for( var key in futures ){
						expect(	futures[ key ].get() ).toBeStruct();
					}
				});


			
			});
		
		});
	}
	
}