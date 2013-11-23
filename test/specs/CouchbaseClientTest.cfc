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

			it( "can flush docs", function(){
				var future = couchbase.flush();
				future.get();
				expect( couchbase.getStats( "vb_active_curr_items" ) ).toBe( 0 );
			});

			it( "can get stats", function(){
				var stats = couchbase.getStats();
				expect( stats ).toBeStruct();
				expect( couchbase.getStats( "vb_active_curr_items" ) ).toBeNumeric();
			});

			it( "can touch an expiration time", function(){
				couchbase.set( id="touch-test", value="value", timeout=10 );
				var future = couchbase.touch( id="touch-test", timeout=0 );
				expect(	future.get() ).toBeTrue();
			});

			describe( "can be constructed ", function(){
				
				it( "with vanilla settings", function(){
					expect(	couchbase ).toBeComponent();
				});

				it( "with config struct literal", function(){
					expect(	new cfcouchbase.CouchbaseClient( config={servers="http://127.0.0.1:8091", bucketname="default"} ) ).toBeComponent();
				});

				it( "with config object instance", function(){
					var config = new cfcouchbase.config.CouchbaseConfig( bucketname="luis", viewTimeout="1000" );
					expect(	new cfcouchbase.CouchbaseClient( config=config ) ).toBeComponent();
				});

				it( "with config object path", function(){
					expect(	new cfcouchbase.CouchbaseClient( config="test.resources.Config" ) ).toBeComponent();
				});
			
			});

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
			});

			describe( "multiSet operations", function(){
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
					
					expect(	futures.id1.getClass().getName() ).toBe( "net.spy.memcached.internal.OperationFuture" );
					expect(	futures.id2.getClass().getName() ).toBe( "net.spy.memcached.internal.OperationFuture" );
					expect(	futures.id3.getClass().getName() ).toBe( "net.spy.memcached.internal.OperationFuture" );
					
					expect(	couchbase.get( "id1" ) ).toBe( "value1" );
					expect(	couchbase.get( "id2" ) ).toBe( "value2" );
					expect(	couchbase.get( "id3" ) ).toBe( "value3" );
										
				});			
			});


			describe( "replace operations", function(){
				it( "will replace a document", function(){
					var future = couchbase.set( ID="replaceMe", value="whatever", timeout=1 );
					future.get();
					var future = couchbase.replace( ID="replaceMe", value="new value", timeout=1 );
					
					//expect(	future.get() ).toBe( true );
					
					var future = couchbase.replace( ID=createUUID(), value="Not gonna' exist", timeout=1 );
																				
					//expect(	future.get() ).toBe( false );
				});			
			});


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
			});


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
		
		});
	}
	
}