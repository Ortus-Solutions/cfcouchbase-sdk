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
				var oQuery = couchbase.getQuery();
				expect(	oQuery.getClass().getName() ).toBe( "com.couchbase.client.protocol.views.Query" );
			});

			it( "can produce a raw query object with options", function(){
				var oQuery = couchbase.getQuery( { debug: true, limit: 10 } );
				expect(	oQuery.getClass().getName() ).toBe( "com.couchbase.client.protocol.views.Query" );
				var args = oQuery.getArgs();
				expect(	args[ "debug" ] ).toBeTrue();
				expect(	args[ "limit" ] ).toBe( 10 );
			});

			it( "can do a raw query", function(){
				var oQuery = couchbase.getQuery( { limit: 10, includeDocs:true } );
				var oView  = couchbase.getView( "beer", "brewery_beers" );
				var results = couchbase.rawquery( oView, oQuery );
				expect(	results.getMap() ).toBeStruct();
			});

			it( "can do a enhanced query with no docs", function(){
				var results = couchbase.query( 'beer', 'brewery_beers', { limit: 100 } );
				//debug( results );
				expect(	results ).toBeArray();
				expect(	arrayLen( results ) ).toBeGT( 1 );
			});

			it( "can do a deserialized query with docs", function(){
				var results = couchbase.query( 'beer', 'brewery_beers', { limit: 100, includeDocs: true} );
				//debug( results );
				expect(	results ).toBeArray();
				expect(	arrayLen( results ) ).toBeGT( 1 );
				expect(	results[ 1 ].document ).toBeStruct();
			});

			it( "can do a non-deserialized query with docs", function(){
				var results = couchbase.query( 'beer', 'brewery_beers', { limit: 100, includeDocs: true}, false );
				//debug( results );
				expect(	results ).toBeArray();
				expect(	arrayLen( results ) ).toBeGT( 1 );
				expect(	results[ 1 ].document ).toBeString();
			});

			it( "can do a paginated query with docs", function(){
				var results = couchbase.query( 'beer', 'brewery_beers', { limit: 10, skip: 20, includeDocs: true}, false );
				//debug( results );
				expect(	results ).toBeArray();
				expect(	arrayLen( results ) ).toBe( 10 );
			});

			it( "can do a query with a filter", function(){
				// filter out beers
				var results = couchbase.query( designDocument='beer', 
											   view='brewery_beers', 
											   options={ limit: 10, includeDocs: true},
											   filter=function( row ){
											   	return ( false );
											   	} );
				//debug( results );
				expect(	results ).toBeArray();
				expect(	arrayLen( results ) ).toBe( 0 );
				//expect( results[ 1 ].document ).toBeStruct();
			});

			it( "can do a query with custom transformations", function(){
				// filter out beers
				var results = couchbase.query( designDocument='beer', 
											   view='brewery_beers', 
											   options={ limit: 100, includeDocs: true},
											   deserialize=false,
											   transform=function( row ){
											   	arguments.row.document = deserializeJSON( arguments.row.document );
											   	} );
				//debug( results );
				expect(	results ).toBeArray();
				expect(	arrayLen( results ) ).toBeGT( 1 );
				expect(	results[ 1 ].document ).notToBeString();
			});

			it( "can do a grouped query", function(){
				var results = couchbase.query( 'beer', 'by_location', { limit: 10, reduce:true, groupLevel:1 }, false );
				expect(	results ).toBeArray();
				expect(	results[ 1 ].value ).toBeNumeric();
				expect(	len( results[ 1 ].key ) ).toBeGT( 0 );
			});
		
		});
	}
	
}