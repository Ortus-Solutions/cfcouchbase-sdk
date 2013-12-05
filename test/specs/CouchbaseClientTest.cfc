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

			it( "can get available servers", function(){
				var servers = couchbase.getAvailableServers();
				expect(	arrayLen( servers ) ).toBeGTE( 1 );
			});

			it( "can get unavailable servers", function(){
				var servers = couchbase.getUnAvailableServers();
				expect(	arrayLen( servers ) ).toBe( 0 );
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
					 
					expect(	result.CAS ).toBeNumeric(); 
					expect(	result.value ).toBe( data );
					
				});		

				it( "of an invalid object with CAS", function(){
					expect(	couchbase.get( "Nothing123" ) ).toBeNull();
				});
				
				it( "of a valid object with touch", function(){
					var data = now();
					// Set with 5 minute timeout
					var future = couchbase.set( ID="unittest-touch", value=data, timeout=5 ).get();
					var stats = couchbase.getDocStats( "unittest-touch" ).get();
					
					var original_exptime = stats[ "key_exptime" ];
					
					// Touch with 10 minute timeout
					var result = couchbase.getAndTouch( "unittest-touch", 10 );
					 
					expect(	result.CAS ).toBeNumeric(); 
					expect(	result.value ).toBe( data );
										
					var stats = couchbase.getDocStats( "unittest-touch" ).get();
					
					// The timeout should now be 5 minutes farther in the future
					expect(	stats[ "key_exptime" ] > original_exptime ).toBeTrue();
					
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
					
					expect(	result.id1 ).toBe( "value1" );
					expect(	result.id2 ).toBe( "value2" );
					expect(	result.id3 ).toBe( "value3" );
					
					expect(	result ).notToHaveKey( "not_existant" );
				});

				/**************************************************************/
				/**************** async operations ******************************/
				/**************************************************************/
				describe( "that are asynchronous", function(){
					
					it( "with valid object", function(){
						couchbase.set( id="asyncget", value="value" );
						var f = couchbase.asyncGet( id="asyncget" );
						expect( f.get(), "value" );
					});

					it( "with invalid object", function(){
						var f = couchbase.asyncGet( id="I am an invalid object" );
						expect( f.get() ).toBeNull();
					});

					it( "with CAS", function(){
						couchbase.set( id="asyncgetWithCas", value="value" );
						var f = couchbase.asyncGetWithCas( id="asyncgetWithCas" );
						var cas = f.get();
						expect( cas.getValue() ).toBe( "value" );
						expect( cas.getCas() ).notToBeEmpty();
					});

					it( "with touch", function(){
						var data = now();
						// Set with 5 minute timeout
						var future = couchbase.set( ID="unittest-asynctouch", value=data, timeout=5 ).get();
						var stats = couchbase.getDocStats( "unittest-asynctouch" ).get();
						
						var original_exptime = stats[ "key_exptime" ];
						
						// Touch with 10 minute timeout
						var casValue = couchbase.asyncGetAndTouch( "unittest-asynctouch", 10 ).get();

						expect(	casValue.getCas() ).toBeNumeric(); 
						expect(	casValue.getValue() ).toBe( data );
											
						var stats = couchbase.getDocStats( "unittest-asynctouch" ).get();
						
						// The timeout should now be 5 minutes farther in the future
						expect(	stats[ "key_exptime" ] > original_exptime ).toBeTrue();
						
					});

					it( "with multiple IDs", function(){
						couchbase.set( ID="async-id1", value="value1" ).get();
						couchbase.set( ID="async-id2", value="value2" ).get();
						couchbase.set( ID="async-id3", value="value3" ).get();
						
						var result = couchbase.asyncGetMulti( ["async-ID1","async-ID2","async-ID3","not_existant"] ).get();
						
						debug( var="Hello", duplicate=true );
						

						expect(	result[ "async-id1" ] ).toBe( "value1" );
						expect(	result[ "async-id2" ] ).toBe( "value2" );
						expect(	result[ "async-id3" ] ).toBe( "value3" );
						
						expect(	result ).notToHaveKey( "not_existant" );
					});

					
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

			/**************************************************************/
			/**************** append/prepend operations ****************************/
			/**************************************************************/
			describe( "append+prepend operations", function(){
			
				it( "can append", function(){
					couchbase.set( id="append-test1", value="Hello" ).get();
					couchbase.append( id="append-test1", value=" Luis" );

					var value = couchbase.get( "append-test1" );
					expect( value ).toBe( "Hello Luis" );
					
				});

				it( "can append with CAS", function(){
					var f = couchbase.set( id="append-test2", value="Hello" );
					couchbase.append( id="append-test2", value=" Luis Majano", cas=f.getCas() );
					
					var value = couchbase.get( "append-test2" );
					expect( value ).toBe( "Hello Luis Majano" );
				});

				it( "can prepend", function(){
					couchbase.set( id="prepend-test1", value="Hello" ).get();
					couchbase.prepend( id="prepend-test1", value="Hola and " );

					var value = couchbase.get( "prepend-test1" );
					expect( value ).toBe( "Hola and Hello" );
					
				});

				it( "can prepend with CAS", function(){
					var f = couchbase.set( id="prepend-test2", value="Luis" );
					couchbase.prepend( id="prepend-test2", value="Hola ", cas=f.getCas() );
					
					var value = couchbase.get( "prepend-test2" );
					expect( value ).toBe( "Hola Luis" );
				});

			});
		
		});
	}
	
}