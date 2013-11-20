/**
* My BDD Test
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

			it( "was constructed", function(){
				expect(	couchbase ).toBeComponent();
			});

			describe( "set operations", function(){
				it( "with just key and value", function(){
					var future = couchbase.set( key="unittest", value="hello" );
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