/**
* My BDD Test
*/
component{
	
/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
	}

	function afterAll(){
	}

/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "SDK Utility", function(){

			beforeEach(function(){
				util = new cfcouchbase.util.Utility();
			});

			it( "can format servers correctly", function(){
				expect(	util.formatServers( "127.0.0.1:8091" ) ).toBe( [ "http://127.0.0.1:8091/pools" ]);
				expect(	util.formatServers( "127.0.0.1:8091/pools" ) ).toBe( [ "http://127.0.0.1:8091/pools" ]);
				expect(	util.formatServers( ["127.0.0.1:8091/pools"] ) ).toBe( [ "http://127.0.0.1:8091/pools" ]);
				expect(	util.formatServers( "127.0.0.1:8091/pools,http://localhost:8091" ) ).toBe( [ "http://127.0.0.1:8091/pools", "http://localhost:8091/pools" ]);
			});

			it( "can build java URIs", function(){
				var list = util.buildServerURIs( "127.0.0.1:8091" );
				expect( list ).toBeArray();
				expect( list[ 1 ] ).toBeInstanceOf( "java.net.URI" );
			});
		
		});
	}
	
}