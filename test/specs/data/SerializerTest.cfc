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
* This test requires there to be a default bucket installed in the Couchbase server
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
				//debug( r );
				expect(	r ).toBe( serializeJSON( data ) );
			});

			it( "works with arrays", function(){
				var data = [ 1,2,3 ];
				var r = couchbase.serializeData( data );
				//debug( r );
				expect(	r ).toBe( serializeJSON( data ) );
			});

			it( "works with queries", function(){
				var data = querySim( "id, name
					1 | luis
					2 | nolan
					3 | brad");
				var r = couchbase.serializeData( data );
				//debug( r );
				var d = deserializeJSON( r );
				expect(	d ).toHaveKey( "type" );
				expect(	d ).toHaveKey( "binary" );
			});
		
		});

		describe( "Couchbase client serialize/deserialize storage", function(){
		
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


			describe( "Serialize/deserialize CFCs", function(){

				it( "of objects with $serialize() methods", function(){
					var data = new test.resources.User();
					data.setName( "Luis Majano" );
					data.setAge( 999 );
	
					couchbase.set( id="object-with-serialize", value=data ).get();
	
					var r = couchbase.get( id="object-with-serialize", deserialize=false );
					r = deserializeJSON( r );
	
					expect(	r ).toHaveKey( "type" );
					expect(	r ).toHaveKey( "when" );
					expect(	r.name ).toBe( "Luis Majano" );
	
				});

				it( "of objects with $deserialize() methods", function(){
					var user = new test.resources.User();
					user.setName( "Brad Wood" );
					user.setAge( 21 );
	
					couchbase.set( id="object-with-deserialize", value=user ).get();
	
					var reinflatedUser = couchbase.get( id="object-with-deserialize", inflateTo='test.resources.User' );
						
					expect(	reinflatedUser.getName() ).toBe( 'Brad Wood' );
					expect(	reinflatedUser.getAge() ).toBe( 21 );
	
				});
	
				it( "of objects with properties", function(){
					var data = new test.resources.UserSimple();
					data.setFirstName( "Luis" );
					data.setLastName( "Majano" );
					data.setAge( 999 );
	
					couchbase.set( id="object-funky", value=data ).get();
	
					// Access the raw data
					var rawData = couchbase.get( id="object-funky" );
					
					expect(	rawData ).toBeStruct();
					expect(	rawData.age ).toBe( 999 );
					expect(	rawData.lastName ).toBe( "Majano" );
					expect(	rawData.firstName ).toBe( "Luis" );
										
					// Or get a reinflated object
					var reinflatedUser = couchbase.get( id="object-funky", inflateTo='test.resources.UserSimple' );
					
					expect(	reinflatedUser ).toBeComponent();
					expect(	reinflatedUser.getAge() ).toBe( 999 );
					expect(	reinflatedUser.getLastName() ).toBe( "Majano" );
					expect(	reinflatedUser.getFirstName() ).toBe( "Luis" );
					
	
				});
	
				it( "with inflateTo object", function(){
					var data = new test.resources.UserSimple();
					data.setFirstName( "Luis" );
					data.setLastName( "Majano" );
					data.setAge( 999 );
	
					couchbase.set( id="object-funky", value=data ).get();
	 
					var reinflatedUser = couchbase.get( id="object-funky", inflateTo= new test.resources.UserSimple() );
					
					expect(	reinflatedUser ).toBeComponent();
					expect(	reinflatedUser.getAge() ).toBe( 999 );
					expect(	reinflatedUser.getLastName() ).toBe( "Majano" );
					expect(	reinflatedUser.getFirstName() ).toBe( "Luis" );
					
				});
	
				it( "with inflateTo closure", function(){
					var data = new test.resources.UserSimple();
					data.setFirstName( "Luis" );
					data.setLastName( "Majano" );
					data.setAge( 999 );
	
					couchbase.set( id="object-funky", value=data ).get();
	 
					var reinflatedUser = couchbase.get(
						id="object-funky",
						inflateTo= function( data ) {
							return new test.resources.UserSimple();
						} 
					);
					
					expect(	reinflatedUser ).toBeComponent();
					expect(	reinflatedUser.getAge() ).toBe( 999 );
					expect(	reinflatedUser.getLastName() ).toBe( "Majano" );
					expect(	reinflatedUser.getFirstName() ).toBe( "Luis" );
					
				});
		
				it( "of objects with no properties", function(){
					var data = new test.resources.Basic();
					
					couchbase.set( id="object-noproperties", value=data ).get();
	
					var r = couchbase.get( id="object-noproperties" );
					
					expect(	r ).toBeComponent();
					expect(	r.name ).toBe( data.name );
					expect(	r.version ).toBe( data.version );
					expect(	r.created ).toBe( data.created );
	
				});
	
				it( "of objects with autoInflate and properties", function(){
					var data = new test.resources.UserSimpleAuto();
					data.setFirstName( "Luis" );
					data.setLastName( "Majano" );
					data.setAge( 999 );
	
					couchbase.set( id="object-auto", value=data ).get();
	
					var r = couchbase.get( id="object-auto" );
						
					expect(	r ).toBeComponent();
					expect(	r.getAge() ).toBe( 999 );
					expect(	r.getLastName() ).toBe( "Majano" );
					expect(	r.getFirstName() ).toBe( "Luis" );
	
				});
	
				it( "of autoInflate objects overridding inflateTo", function(){
					var data = new test.resources.UserSimpleAuto();
					data.setFirstName( "Luis" );
					data.setLastName( "Majano" );
					data.setAge( 999 );
	
					couchbase.set( id="object-auto", value=data ).get();
						
					var reinflatedUser = couchbase.get(
						id="object-auto",
						inflateTo= function( data ) {
							var user = new test.resources.UserSimple();
							user.foo = 'bar';
							return user;
						} 
					);
										
					expect(	reinflatedUser ).toHaveKey( 'foo' );
					expect(	reinflatedUser.foo ).toBe( 'bar' );
	
				});
				
				it( "of objects using their own non-JSON serialization", function(){
					var user = new test.resources.CustomUser();
					user.setFirstName( "Brad" );
					user.setLastName( "Wood" );
					user.setAge( 45 );
	
					couchbase.set( id="half-pipe", value=user ).get();
	
					var reinflatedUser = couchbase.get( id="half-pipe", inflateTo='test.resources.CustomUser' );
											
					expect(	reinflatedUser.getFirstName() ).toBe( 'Brad' );
					expect(	reinflatedUser.getLastName() ).toBe( 'Wood' );
					expect(	reinflatedUser.getAge() ).toBe( 45 );
	
				});
				
				it( "of objects using a query", function(){
					var qrySimpleUsers = querySim( "id,firstName,lastName,Age
						1 | Luis | Too-Cool | 25
						2 | Nolan | Too-Cold | 19
						3 | Brad | Too-Hyper | 7");
					
					couchbase.set( id="qrySimpleUsers", value=qrySimpleUsers ).get();
		
					// Get back an array of user object
					var reinflatedUsers = couchbase.get( id="qrySimpleUsers", inflateTo='test.resources.UserSimple' );
																						
					expect(	reinflatedUsers ).toBeArray();								
					expect(	reinflatedUsers ).toHaveLength( 3 );			
					expect(	reinflatedUsers[1].getFirstName() ).toBe( 'Luis' );
					expect(	reinflatedUsers[1].getLastName() ).toBe( 'Too-Cool' );
					expect(	reinflatedUsers[1].getAge() ).toBe( 25 );
	
				});
				
				it( "of objects using a view", function(){
					
					var data = new test.resources.UserSimpleAuto();
					data.setFirstName( "Mickey" );
					data.setLastName( "Mouse" );
					data.setAge( 87 );	
					couchbase.set( id="user42", value=data ).get();	
					
					data = new test.resources.UserSimpleAuto();
					data.setFirstName( "Donald" );
					data.setLastName( "Duck" );
					data.setAge( 28 );	
					couchbase.set( id="user43", value=data ).get();	
					
					data = new test.resources.UserSimpleAuto();
					data.setFirstName( "Minney" );
					data.setLastName( "Mouse" );
					data.setAge( 100 );	
					couchbase.set( id="user44", value=data ).get();
					
					couchbase.saveView(
						'serializeTest',
						'allUserSimples',
						'function (doc, meta) {
						  if ( doc.type && doc.type == ''cfcouchbase-cfcdata''
						  	   && doc.classpath && doc.classpath == ''test.resources.UserSimpleAuto'' ) {
						    emit(doc.data.firstName, null);
						  }
						}'
					);
						
					// Get back an array of populated objects
					var results = couchbase.query(
						'serializeTest',
						'allUserSimples',
						{
							includeDocs=true
						}
					);
					
					expect( results ).toBeArray();
					expect( results[1] ).toBeStruct();
					expect( results[1].document ).toBeComponent();
					expect( results[1].document.getAge() ).toBeGT( 0 );
	
				});
		
			});
			
		});
	}
	
}