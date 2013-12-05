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
* This test requires the beer-sample to be installed in the Couchbase server
*/
component{
	
/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		couchbase = new cfcouchbase.CouchbaseClient( { bucketName="beer-sample" } );
	}

	function afterAll(){
		couchbase.shutdown( 10 );
	}

/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "View Operations", function(){
		
			it( "can get a view", function(){
				var view = couchbase.getView( 'beer', 'by_location' );
				expect( view.getViewName() ).toBe( 'by_location' );
			});

			it( "can produce a raw query object", function(){
				var oQuery = couchbase.newQuery();
				expect(	oQuery.getClass().getName() ).toBe( "com.couchbase.client.protocol.views.Query" );
			});

			it( "can produce a raw query object with options", function(){
				var oQuery = couchbase.newQuery( { debug: true, limit: javaCast( "int", 10 ) } );
				expect(	oQuery.getClass().getName() ).toBe( "com.couchbase.client.protocol.views.Query" );
				var args = oQuery.getArgs();
				expect(	args[ "debug" ] ).toBeTrue();
				expect(	args[ "limit" ] ).toBe( 10 );
			});

			it( "can do a raw query", function(){
				var oQuery = couchbase.newQuery( { limit: javaCast( "int", 10 ), includeDocs:true } );
				var oView  = couchbase.getView( "beer", "brewery_beers" );
				var results = couchbase.query( oView, oQuery );

				expect(	results.getMap() ).toBeStruct();
			});
		
		});
	}
	
}