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
		couchbase.shutdown();
	}

/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "Couchbase Client", function(){

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
				it( "with just key and value", function(){
					var future = couchbase.set( key="unittest", value="hello" );
					while( !future.isDone() ){
						// wait for it to finish.
					}	
					expect(	future.getStatus().isSuccess() ).toBeTrue();
				});	

				it( "with json data", function(){
					var data = serializeJSON( { "name"="Lui", "awesome"=true, "when"=now(), "children" = [1,2] } );
					var future = couchbase.set( key="unittest-json", value=data );
					while( !future.isDone() ){
						// wait for it to finish.
					}		
					expect(	future.getStatus().isSuccess() ).toBeTrue();
				});		
			});


			describe( "get operations", function(){
				it( "of a valid object ", function(){
					var data = now();
					var future = couchbase.set( key="unittest", value=data );
					while( !future.isDone() ){
						// wait for it to finish.
					}	
					expect(	couchbase.get( "unittest" ) ).toBe( data );
				});			
			});
		
		});
	}
	
}