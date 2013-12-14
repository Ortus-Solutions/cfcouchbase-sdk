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
		couchbase = new cfcouchbase.CouchbaseClient( { bucketName="default" } );
	}

	function afterAll(){
		couchbase.shutdown( 10 );
	}

/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "Couchbase Client Serializer", function(){
		
			it( "passes back simple values", function(){
				var r = couchbase.serializeData( "hello" );
				expect(	r ).toBe( "hello" );
			});

			it( "passes back json", function(){
				var data = serializeJSON( { name = "luis", awesome = true } );
				var r = couchbase.serializeData( data );
				expect(	r ).toBe( data );
			});

			it( "works with structs", function(){
				var data = { name = "luis", awesome = true };
				var r = couchbase.serializeData( data );
				debug( r );
				expect(	r ).toBe( serializeJSON( data ) );
			});

			it( "works with arrays", function(){
				var data = [ 1,2,3 ];
				var r = couchbase.serializeData( data );
				debug( r );
				expect(	r ).toBe( serializeJSON( data ) );
			});

			it( "works with queries", function(){
				var data = querySim( "id, name
					1 | luis
					2 | nolan
					3 | brad");
				var r = couchbase.serializeData( data );
				debug( r );
				expect(	r ).toBe( serializeJSON( data ) );
			});
		
		});

		describe( "Couchbase client serialized storage", function(){
		
			it( "of query values", function(){
				var data = querySim( "id, name
					1 | luis
					2 | nolan
					3 | brad");
				
				couchbase.set( id="complex-query", value=data ).get();

				var r = couchbase.get( id="complex-query" );
				expect(	r ).toBe( data );
			});

			it( "of array values", function(){
				var data = [ 1,2,3, { name="luis", awesome=true } ];
				couchbase.set( id="complex-array", value=data ).get();

				var r = couchbase.get( id="complex-array" );
				expect(	r ).toBe( data );
			});

			it( "of struct values", function(){
				var data = { name="luis", awesome=true, children=[1,2] };
				couchbase.set( id="complex-struct", value=data ).get();

				var r = couchbase.get( id="complex-struct" );
				expect(	r ).toBe( data );
			});
		
		});
	}
	
}