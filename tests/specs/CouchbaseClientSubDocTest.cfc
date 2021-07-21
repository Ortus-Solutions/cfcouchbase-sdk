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
* This test requires the travel-sample to be installed in the Couchbase server
*/
component extends="testbox.system.BaseSpec"{

/*********************************** LIFE CYCLE Methods ***********************************/

  function beforeAll(){
    couchbase = new cfcouchbase.CouchbaseClient( {
      bucketName="default",
      username="cfcouchbase",
      password="password"
    } );
  }

  function afterAll(){
    couchbase.shutdown( 10 );
  }

/*********************************** BDD SUITES ***********************************/

  function run(){
    describe( "Mutation Operations", function(){

      describe( "Array Operations", function(){
        it( "can append a unique item to an array", function(){
          var key = "mutate_array_test";
          couchbase.upsert( id=key, value={ "id": key, "names": [ "Luis", "Brad" ] } );
          var mutate = couchbase.mutateIn( key );
          mutate
            .arrayAddUnique( "names", "Aaron" )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "names" );
          expect( doc.names ).toBeArray()
          expect( arrayLen(doc.names) ).toBe( 3 );
          expect( doc.names[3] ).toBe( "Aaron" );
        });

        it( "will not duplicate an existing value of an array", function(){
          var key = "mutate_array_test";
          var mutate = couchbase.mutateIn( key );
          expect( function(){
            mutate
              .arrayAddUnique( "names", "Aaron" )
              .execute();
          })
          .toThrow( type="com.couchbase.client.core.error.subdoc.PathExistsException" );
        });

        it( "can append an item to the end of an array", function(){
          var key = "mutate_array_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .arrayAppend( "names", "Gavin" )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "names" );
          expect( doc.names ).toBeArray()
          expect( arrayLen(doc.names) ).toBe( 4 );
          expect( doc.names[4] ).toBe( "Gavin" );
        });

        it( "can append multiple items to the end of an array", function(){
          var key = "mutate_array_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .arrayAppendAll( "names", [ "Esme", "Jorge" ] )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "names" );
          expect( doc.names ).toBeArray()
          expect( arrayLen(doc.names) ).toBe( 6 );
          expect( doc.names[5] ).toBe( "Esme" );
          expect( doc.names[6] ).toBe( "Jorge" );
        });

        it( "can insert a value at a specific position in an array", function(){
          var key = "mutate_array_test";

          var mutate = couchbase.mutateIn( key );
          mutate
            // note: the index is 0 based
            .arrayInsert( "names[3]", "Curt" )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "names" );
          expect( doc.names ).toBeArray()
          expect( arrayLen(doc.names) ).toBe( 7 );
          expect( doc.names[4] ).toBe( "Curt" );
        });

        it( "can insert multiple values at a specific position in an array ", function(){
          var key = "mutate_array_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            // note: the index is 0 based
            .arrayInsertAll( "names[5]", [ "Jon", "Scott" ] )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "names" );
          expect( doc.names ).toBeArray()
          expect( arrayLen(doc.names) ).toBe( 9 );
          expect( doc.names[6] ).toBe( "Jon" );
          expect( doc.names[7] ).toBe( "Scott" );
        });

        it( "can preprend a value to the beginning of an array", function(){
          var key = "mutate_array_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            // note: the index is 0 based
            .arrayPrepend( "names", "Nathaniel" )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "names" );
          expect( doc.names ).toBeArray()
          expect( arrayLen(doc.names) ).toBe( 10 );
          expect( doc.names[1] ).toBe( "Nathaniel" );
        });

        it( "can prepend multiple values to the beginning of an array", function(){
          var key = "mutate_array_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            // note: the index is 0 based
            .arrayPrependAll( "names", [ "George", "Seth" ] )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "names" );
          expect( doc.names ).toBeArray()
          expect( arrayLen(doc.names) ).toBe( 12 );
          expect( doc.names[1] ).toBe( "George" );
          expect( doc.names[2] ).toBe( "Seth" );
        });
      });

      describe( "Counter Operations", function(){
        it( "can increment a value by 1", function(){
          var key = "mutate_counter_test";
          couchbase.upsert( id=key, value={ "id": key, "name": "Aaron", "age": 30 } );
          var mutate = couchbase.mutateIn( key );
          mutate
            .counter( "age", 1 )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "age" );
          expect( doc.age ).toBe( 31 );
        });

        it( "can increment a value by 10", function(){
          var key = "mutate_counter_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .counter( "age", 10 )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "age" );
          expect( doc.age ).toBe( 41 );
        });

        it( "can decrement a value by 1", function(){
          var key = "mutate_counter_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .counter( "age", -1 )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "age" );
          expect( doc.age ).toBe( 40 );
        });

        it( "can decrement a value by 10", function(){
          var key = "mutate_counter_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .counter( "age", -10 )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "age" );
          expect( doc.age ).toBe( 30 );
        });

        it( "can create value if the path does not exist", function(){
          var key = "mutate_counter_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .counter( "logins", 1 )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "logins" );
          expect( doc.logins ).toBe( 1 );
        });

      });

      describe( "Fragment Operations", function(){

        beforeEach( function(){
          var key = "mutate_fragment_test";
          couchbase.upsert( id=key, value={ "id": key } );
        } );

        it( "can insert a fragment", function(){
          var key = "mutate_fragment_test";
          couchbase.upsert( id=key, value={ "id": key } );
          var mutate = couchbase.mutateIn( key );
          mutate
            .insert( "details", {
              "first_name": "Aaron",
              "last_name": "Benton"
            } )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "details" );
          expect( doc.details ).toBeStruct();
          expect( doc.details ).toHaveKey( "first_name" );
          expect( doc.details.first_name ).toBe( "Aaron" );
          expect( doc.details.last_name ).toBe( "Benton" );
        });

        it( "can insert a nested fragment", function(){
          var key = "mutate_fragment_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .insert( "details.address.home", {
              "address": "123 CF Way",
              "address_2": "",
              "city": "Greensboro",
              "state": "NC",
              "zip": "27409",
            } )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "details" );
          expect( doc.details ).toHaveKey( "address" );
          expect( doc.details.address ).toBeStruct();
          expect( doc.details.address ).toHaveKey( "home" );
          expect( doc.details.address.home ).toBeStruct();
          expect( doc.details.address.home.address ).toBe( "123 CF Way" );
          expect( doc.details.address.home.address_2 ).toBe( "" );
          expect( doc.details.address.home.city ).toBe( "Greensboro" );
          expect( doc.details.address.home.state ).toBe( "NC" );
          expect( doc.details.address.home.zip ).toBe( "27409" );
        });

        it( "will error if the path exists", function(){
          var key = "mutate_fragment_test";
          var mutate = couchbase.mutateIn( key );
            mutate
              .insert( "details", {} )
              .execute();
              
          var mutate = couchbase.mutateIn( key );
          expect( function(){
            mutate
              .insert( "details", {} )
              .execute();
          })
          .toThrow( type="com.couchbase.client.core.error.subdoc.PathExistsException" );

        });

        it( "can replace a fragment", function(){
          var key = "mutate_fragment_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .insert( "details.address.home", {
              "address": "123 CF Way",
              "address_2": "",
              "city": "Greensboro",
              "state": "NC",
              "zip": "27409",
            } )
            .execute();
          var mutate = couchbase.mutateIn( key );
          mutate
            .replace( "details.address.home", {
              "address": "123 RockChalk Way",
              "address_2": "",
              "city": "Salina",
              "state": "KS",
              "zip": "67401",
            } )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "details" );
          expect( doc.details ).toHaveKey( "address" );
          expect( doc.details.address ).toBeStruct();
          expect( doc.details.address ).toHaveKey( "home" );
          expect( doc.details.address.home ).toBeStruct();
          expect( doc.details.address.home.address ).toBe( "123 RockChalk Way" );
          expect( doc.details.address.home.address_2 ).toBe( "" );
          expect( doc.details.address.home.city ).toBe( "Salina" );
          expect( doc.details.address.home.state ).toBe( "KS" );
          expect( doc.details.address.home.zip ).toBe( "67401" );
        });

        it( "can insert a fragment using upsert", function(){
          var key = "mutate_fragment_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .upsert( "details.address.work", {
              "address": "873 Lucee St",
              "address_2": "",
              "city": "Houston",
              "state": "TX",
              "zip": "87834",
            } )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "details" );
          expect( doc.details ).toHaveKey( "address" );
          expect( doc.details.address ).toBeStruct();
          expect( doc.details.address ).toHaveKey( "work" );
          expect( doc.details.address.work ).toBeStruct();
          expect( doc.details.address.work.address ).toBe( "873 Lucee St" );
          expect( doc.details.address.work.address_2 ).toBe( "" );
          expect( doc.details.address.work.city ).toBe( "Houston" );
          expect( doc.details.address.work.state ).toBe( "TX" );
          expect( doc.details.address.work.zip ).toBe( "87834" );
        });

        it( "can update a fragment using upsert", function(){
          var key = "mutate_fragment_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .upsert( "details.address.work", {
              "address": "873 Lucee St",
              "address_2": "",
              "city": "Houston",
              "state": "TX",
              "zip": "87834",
            } )
            .execute();
          var mutate = couchbase.mutateIn( key );
          mutate
            .upsert( "details.address.work", {
              "address": "873 Lucee St",
              "address_2": "",
              "city": "San Francisco",
              "state": "CA",
              "zip": "09821",
            } )
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "details" );
          expect( doc.details ).toHaveKey( "address" );
          expect( doc.details.address ).toBeStruct();
          expect( doc.details.address ).toHaveKey( "work" );
          expect( doc.details.address.work ).toBeStruct();
          expect( doc.details.address.work.address ).toBe( "873 Lucee St" );
          expect( doc.details.address.work.address_2 ).toBe( "" );
          expect( doc.details.address.work.city ).toBe( "San Francisco" );
          expect( doc.details.address.work.state ).toBe( "CA" );
          expect( doc.details.address.work.zip ).toBe( "09821" );
        });

        it( "can remove a fragment", function(){
          var key = "mutate_fragment_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .upsert( "details.address.work", {
              "address": "873 Lucee St",
              "address_2": "",
              "city": "San Francisco",
              "state": "CA",
              "zip": "09821",
            } )
            .execute();
          var mutate = couchbase.mutateIn( key );
          mutate
            .remove( "details.address.work")
            .execute();
          var doc = couchbase.get( id=key );
          expect( doc ).toHaveKey( "details" );
          expect( doc.details ).toHaveKey( "address" );
          expect( doc.details.address ).toBeStruct();
          expect( doc.details.address ).notToHaveKey( "work" );
        });

        it( "will error when removing if the path does not exist", function(){
          var key = "mutate_fragment_test";
          var mutate = couchbase.mutateIn( key );
          expect( function(){
            mutate
              .remove( "details.address.unknown")
              .execute();
          })
          .toThrow( type="com.couchbase.client.core.error.subdoc.PathNotFoundException" );
        });
      });

      describe( "Document Operations", function(){
        it( "can update a document with a CAS value", function(){
          var key = "mutate_document_test";
          couchbase.upsert( id=key, value={ "id": key, "name": "Aaron" } );
          var cas = couchbase.getWithCAS( id=key ).cas;
          var mutate = couchbase.mutateIn( key );
          mutate
            .upsert( "name", "Luis" )
            .withCas( cas )
            .execute();
          var doc = couchbase.getWithCAS( id=key );
          expect( doc.value ).toHaveKey( "name" );
          expect( doc.value.name ).toBe( "Luis" );
          expect( doc.cas ).notToBe( cas );
        });

        it( "will error with an invalid CAS", function(){
          var key = "mutate_document_test";
          var mutate = couchbase.mutateIn( key );
          expect( function(){
            mutate
              .upsert( "name", "Luis" )
              .withCas( 123456789 )
              .execute();
          })
          .toThrow( type="com.couchbase.client.core.error.CasMismatchException" );
        });

        it( "can update a document with durability (persistTo only)", function(){
          var key = "mutate_document_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .upsert( "name", "Brad" )
            .withDurability( "ONE" )
            .execute();
          var doc = couchbase.getWithCAS( id=key );
          expect( doc.value ).toHaveKey( "name" );
          expect( doc.value.name ).toBe( "Brad" );
        });

        it( "can update a document with durability (replicateTo only)", function(){
          var key = "mutate_document_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .upsert( "name", "Gavin" )
            .withDurability( replicateTo="NONE" )
            .execute();
          var doc = couchbase.getWithCAS( id=key );
          expect( doc.value ).toHaveKey( "name" );
          expect( doc.value.name ).toBe( "Gavin" );
        });

        it( "can update a document with durability (persistTo and replicateTo)", function(){
          var key = "mutate_document_test";
          var mutate = couchbase.mutateIn( key );
          mutate
            .upsert( "name", "Gavin" )
            .withDurability( "ONE", "NONE" )
            .execute();
          var doc = couchbase.getWithCAS( id=key );
          expect( doc.value ).toHaveKey( "name" );
          expect( doc.value.name ).toBe( "Gavin" );
        });

        it( "can update a document with expiry", function(){
          var key = "mutate_document_test";
          var cas = couchbase.getWithCAS( id=key ).cas;
          var mutate = couchbase.mutateIn( key );
          mutate
            .upsert( "name", "Scott" )
            .withExpiry( 1000 )
            .execute();
          var doc = couchbase.getWithCAS( id=key );
          expect( doc.value ).toHaveKey( "name" );
          expect( doc.value.name ).toBe( "Scott" );
        });

        it( "will error if the document does not exist", function(){
          var key = createUUID();
          var mutate = couchbase.mutateIn( key );
          expect(function(){
          mutate
            .upsert( "name", "Scott" )
            .execute();
          })
          .toThrow( type="com.couchbase.client.core.error.DocumentNotFoundException" );
        });
      });


    });

    describe( "Lookup Operations", function(){
      it( "can retrieve a single value from a document", function(){
        var key = "lookup_test"; // set the key
        // build a test document
        var data = {
          "id": key,
          "doc_type": "user",
          "user_id": 123,
          "account": {
            "username": "Lulu2",
            "password": "aeLfXKc1oz_HIRX",
            "created_on": 1461195393460,
            "modified_on": 1466481462019,
            "last_login": 1466446286881
          },
          "details": {
            "prefix": "Mr.",
            "first_name": "Shirley",
            "middle_name": "Lilly",
            "last_name": "Pacocha",
            "suffix": javaCast( "null", "" ),
            "company": javaCast( "null", "" ),
            "job_title": javaCast( "null", "" ),
            "dob": javaCast( "null", "" ),
            "home_country": "SI"
          },
          "phones": [
            {
              "type": "Main",
              "phone_number": "(742) 635-3219",
              "extension": javaCast( "null", "" ),
              "primary": true
            },
            {
              "type": "Main",
              "phone_number": "(560) 580-3488",
              "extension": "6846",
              "primary": false
            }
          ],
          "emails": [
            {
              "type": "Work",
              "email_address": "Uriel_Marks86@yahoo.com",
              "primary": false
            },
            {
              "type": "Home",
              "email_address": "Joy.Satterfield@yahoo.com",
              "primary": false
            },
            {
              "type": "Work",
              "email_address": "Payton5@gmail.com",
              "primary": true
            }
          ],
          "addresses": [
            {
              "type": "Other",
              "address_1": "7971 Cruickshank Fields Club",
              "address_2": javaCast( "null", "" ),
              "locality": "Kuvaliston",
              "iso_region": "SI-127",
              "postal_code": "94144-6234",
              "iso_country": "SI",
              "primary": false
            },
            {
              "type": "Home",
              "address_1": "5927 Miracle Station Squares",
              "address_2": "Suite 615",
              "locality": "East Jo",
              "iso_region": "SI-127",
              "postal_code": "81102-6012",
              "iso_country": "SI",
              "primary": true
            }
          ]
        };
        couchbase.upsert( id=key, value=data );
        var result = couchbase.lookupIn(key)
          .get( "details.first_name" )
          .exists( "details.last_name" )
          .count( "phones" )
          .execute();

        expect( result ).toBeStruct();
        expect( result ).toHaveKey( "details.first_name" );
        expect( result ).toHaveKey( "details.last_name" );
        expect( result ).toHaveKey( "phones" );
        expect( result[ "details.first_name" ] ).toBe( "Shirley" );
        expect( result[ "details.last_name" ] ).toBe( true );
        expect( result[ "phones" ] ).toBe( 2 );
      });

      it( "will return null value if the path does not exist", function(){
        var key = "lookup_test";
        var result = couchbase.lookupIn(key)
          .get( "path.does.not.exist1" )
          .exists( "path.does.not.exist2" )
          .count( "path.does.not.exist3" )
          .execute();

        expect( result ).toBeStruct();
        expect( result.keyList() ).toInclude( "path.does.not.exist1" );
        expect( result.keyList() ).toInclude( "path.does.not.exist2" );
        expect( result.keyList() ).toInclude( "path.does.not.exist3" );
        expect( isNull( result[ "path.does.not.exist1" ] ) ).toBeTrue();
        expect( result[ "path.does.not.exist2" ] ).toBeFalse();
        expect( isNull( result[ "path.does.not.exist3" ] ) ).toBeTrue();
      });

      it( "will return null result if the document does not exist", function(){
        var key = "lookup_test_doesnotexist";
        var lookup = couchbase.lookupIn(key);
        expect( lookup.get( "details.first_name" ).execute() ).toBeNull();
      });

      it( "can retrieve multiple paths", function(){
        var key = "lookup_test";
        var result = couchbase.lookupIn(key)
          .get('account.username')
          .get('account.password')
          .get('details.first_name')
          .execute();
        expect( result['account.username'] ).toBe( "Lulu2" );
        expect( result['account.password'] ).toBe( "aeLfXKc1oz_HIRX" );
        expect( result['details.first_name'] ).toBe( "Shirley" );
      });

      it( "can retrieve multiple paths from array", function(){
        var key = "lookup_test";
        var lookup = couchbase.lookupIn(key);
        var result = lookup
                      .get( [ "account.username", "account.password", "details.first_name"] )
                      .execute();
        expect( result[ "account.username" ] ).toBe( "Lulu2" );
        expect( result[ "account.password" ] ).toBe( "aeLfXKc1oz_HIRX" );
        expect( result[ "details.first_name" ] ).toBe( "Shirley" );
      });

      it( "can retrieve an array", function(){
        var key = "lookup_test";
        var lookup = couchbase.lookupIn(key);
        var result = lookup
                      .get( 'phones' )
                      .execute();
        expect( result[ "phones" ] ).toBeArray();
      });

      it( "can retrieve an object", function(){
        var key = "lookup_test";
        var lookup = couchbase.lookupIn(key);
        var result = lookup
                      .get( 'details' )
                      .execute();
        expect( result[ "details" ] ).toBeStruct();
      });

      it( "can retrieve multiple paths from multuple arguments", function(){
        var key = "lookup_test";
        var lookup = couchbase.lookupIn(key);
        var result = lookup
                      .get( "account.username", "account.password", "details.first_name" )
                      .execute();
        expect( result[ "account.username" ] ).toBe( "Lulu2" );
        expect( result[ "account.password" ] ).toBe( "aeLfXKc1oz_HIRX" );
        expect( result[ "details.first_name" ] ).toBe( "Shirley" );
      });

      it( "can retrieve a specific array index", function(){
        var key = "lookup_test";
        var result = couchbase.lookupIn(key)
          .get( "emails[2]" ) // note this is a zero based index
          .execute();
        expect( result[ "emails[2]" ] ).toBeStruct();
        expect( result[ "emails[2]" ].type ).toBe( "Work" );
        expect( result[ "emails[2]" ].email_address ).toBe( "Payton5@gmail.com" );
        expect( result[ "emails[2]" ].primary ).toBeTrue();
      });

      it( "can determine if a path exists", function(){
        var key = "lookup_test";
        var lookup = couchbase.lookupIn(key);
        var result = lookup
                      .exists( "details.first_name" )
                      .execute();
        expect( result[ "details.first_name" ] ).toBeTrue();
      });

      it( "can determine if multiple paths exists", function(){
        var key = "lookup_test";
        var lookup = couchbase.lookupIn(key);
        var result = lookup
                      .exists( "details.first_name" )
                      .exists( "account.username" )
                      .execute();
        expect( result[ "details.first_name" ] ).toBeTrue();
        expect( result[ "account.username" ] ).toBeTrue();
      });

      it( "can determine if multiple paths exists from an array", function(){
        var key = "lookup_test";
        var lookup = couchbase.lookupIn(key);
        var result = lookup
                      .exists( [ "details.first_name", "account.username" ] )
                      .execute();
                      debug(result);
        expect( result[ "details.first_name" ] ).toBeTrue();
        expect( result[ "account.username" ] ).toBeTrue();
      });

    });

  }

}
