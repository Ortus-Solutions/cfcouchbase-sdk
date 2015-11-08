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
component extends="testbox.system.BaseSpec"{

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

      /**************************************************************/
      /**************** legacy operations ***************************/
      /**************************************************************/
      describe( "set operations", function(){

        it( "with just ID and value", function(){
          var key = "unittest";
          var doc = couchbase.set( id=key, value="hello" );

          expect( doc ).toBeStruct();
          expect( doc ).toHaveKey( "id" );
          expect( doc ).toHaveKey( "cas" );
          expect( doc ).toHaveKey( "expiry" );
          expect( doc ).toHaveKey( "hashCode" );
          expect( doc.id ).toBe( key );
        });

        it( "with invalid timeout", function(){
            expect( function(){
              couchbase.set( id="unittest", value="hello", timeout=-5 );
            })
            .toThrow( type="InvalidTimeout" );
        });

        it( "with valid timeout", function(){
          var key = "unittest";
          var doc = couchbase.set( id=key, value="hello", timeout=5 );

          expect( doc ).toBeStruct();
          expect( doc ).toHaveKey( "id" );
          expect( doc ).toHaveKey( "cas" );
          expect( doc ).toHaveKey( "expiry" );
          expect( doc ).toHaveKey( "hashCode" );
          expect( doc.id ).toBe( key );
        });

        it( "with timeout less than 30 days", function(){
          couchbase.set( id="ten_minutes", value="I should only last 10 minutes", timeout=10 );
          var doc = couchbase.getWithCAS( id="ten_minutes" );
          debug(doc);
          var currentEpochDate = createObject( "java", "java.util.Date" ).init().getTime() / 1000;
          var tenMinutesInTheFutureEpoch = round( currentEpochDate + ( 10 * 60 ) );

          // See if the expiration date (stored as seconds since epoch) matches what I think it should be.
          //  Just make sure the values are within 10 seconds since I don't know the exact timing of the put() call.
          expect( round(tenMinutesInTheFutureEpoch / 100 ) )
            .toBeCloseTo( round( doc[ "expiry" ] / 100 ), 50 );

        });

        it( "with timeout greater than 30 days", function(){
          couchbase.set( id="fortyFive_days", value="I should last 45 days", timeout=45*24*60 );
          var currentEpochDate = createObject( "java", "java.util.Date" ).init().getTime() / 1000;
          var fortyFiveDaysInTheFutureEpoch = round( currentEpochDate + ( 45 * 60 * 60 * 24 ) );
          var doc = couchbase.getWithCAS( id="fortyFive_days" );
          // See if the expiration date (stored as seconds since epoch) matches what I think it should be.
          //  Just make sure the values are within 10 seconds since I don't know the exact timing of the put() call.
          expect( round( fortyFiveDaysInTheFutureEpoch / 100 ) )
            .toBeCloseTo( round( doc.expiry / 100 ), 50 );

        });

/*

  <cfset currentEpochDate = createObject("java","java.util.Date").init().getTime() / 1000>
  <cfset fortyFiveDaysInTheFutureEpoch = round(currentEpochDate + (45 * 60 * 60 * 24))>
  <cfset cachePut("fortyFive_days","I should last 45 days",CreateTimeSpan(45,0,0,0))>

  <!--- See if the expiration date (stored as seconds since epoch) matches what I think it should be.
    Just make sure the values are within 10 seconds since I don't know the exact timing of the put() call. --->
  <cf_valueEquals left="#round(fortyFiveDaysInTheFutureEpoch/100)#" right="#round(cacheGetMetadata("fortyFive_days").custom.key_exptime/100)#">

*/

        it( "with json data", function(){
          var key = "unittest-json";
          var data = serializeJSON( { "name"="Lui", "awesome"=true, "when"=now(), "children" = [ 1, 2 ] } );
          var doc = couchbase.set( id=key, value=data );

          expect( doc ).toBeStruct();
          expect( doc ).toHaveKey( "id" );
          expect( doc ).toHaveKey( "cas" );
          expect( doc ).toHaveKey( "expiry" );
          expect( doc ).toHaveKey( "hashCode" );
          expect( doc.id ).toBe( key );
        });

        it( "can decrement values", function(){
          var doc = couchbase.upsert( id="unit-decrement", value=10 );
          var result = couchbase.decr( "unit-decrement", 1 );
          expect( result ).toBe( 9 );
        });

        it( "can increment values", function(){
          couchbase.set( id="unit-increment", value="10" );
          var result = couchbase.incr( "unit-increment", 10 );
          expect( result ).toBe( 20 );
        });

        it( "will set multiple documents", function(){
          var data = {
            "id1"="value1",
            "id2"="value2",
            "id3"="value3"
          };
          var results = couchbase.setMulti( data=data, timeout=1 );

          expect( results ).toBeStruct();

          expect( results ).toHaveKey( "id1" );
          expect( results ).toHaveKey( "id2" );
          expect( results ).toHaveKey( "id3" );

          expect( couchbase.get( "id1" ) ).toBe( "value1" );
          expect( couchbase.get( "id2" ) ).toBe( "value2" );
          expect( couchbase.get( "id3" ) ).toBe( "value3" );
        });


        it( "with CAS value that hasn't changed", function(){
          couchbase.set( id="unittest", value="hello" );
          var getResult = couchbase.getWithCAS( id="unittest" );
          var setResult = couchbase.setWithCAS( id="unittest", cas=getResult.cas, value="New Value" );

          expect( setResult ).toBeStruct();
          expect( setResult ).toHaveKey( "status" );
          expect( setResult ).toHaveKey( "detail" );
          expect( setResult.status ).toBe( true );
          expect( setResult.detail ).toBe( "SUCCESS" );
        });

        it( "with CAS value that is out-of-date", function(){
          couchbase.set( id="unittest", value="hello" );
          var getResult = couchbase.getWithCAS( id="unittest" );
          couchbase.set( id="unittest", value="a new value" );
          var setResult = couchbase.setWithCAS( id="unittest", cas=getResult.cas, value="New Value" );

          expect( setResult ).toBeStruct();
          expect( setResult ).toHaveKey( "status" );
          expect( setResult ).toHaveKey( "detail" );
          expect( setResult.status ).toBe( false );
          expect( setResult.detail ).toBe( "CAS_CHANGED" );
        });

        it( "with CAS value and key that doesn't exist", function(){
          var setResult = couchbase.setWithCAS( id=createUUID(), cas=123456789, value="New Value" );

          expect( setResult ).toBeStruct();
          expect( setResult ).toHaveKey( "status" );
          expect( setResult ).toHaveKey( "detail" );
          expect( setResult.status ).toBe( false );
          expect( setResult.detail ).toBe( "NOT_FOUND" );
        });

        describe( "that are asynchronous", function() {

          it( "can decrement values asynchronously", function(){
            expect( function(){
              couchbase.asyncDecr( "unit-decrement", 1 )
            })
            .toThrow( type="CouchbaseClient.NotSupported" );
          });

          it( "can increment values asynchronously", function(){
              expect( function(){
                couchbase.asyncIncr( "unit-increment", 1 )
              })
              .toThrow( type="CouchbaseClient.NotSupported" );
          });

        });

        describe( "Durability Options", function() {

          it( "with default persisTo and replicateTo", function(){
            var key = "unittest";
            var doc = couchbase.set( id=key, value="hello" );

            expect( doc ).toBeStruct();
            expect( doc ).toHaveKey( "id" );
            expect( doc ).toHaveKey( "cas" );
            expect( doc ).toHaveKey( "expiry" );
            expect( doc ).toHaveKey( "hashCode" );
            expect( doc.id ).toBe( key );
          });

          it( "with invalid persisTo", function(){
            expect( function(){
              couchbase.set( id="unittest", value="hello", persistTo="invalid" );
            })
            .toThrow( type="InvalidPersistTo" );
          });

          it( "with invalid replicateTo", function(){
            expect( function(){
              couchbase.set( id="unittest", value="hello", replicateTo="invalid" );
            })
            .toThrow( type="InvalidReplicateTo" );
          });

          it( "with valid persisTo", function(){
            var cas = 0;
            // Extra whitespace
            var doc = couchbase.set( id="unittest", value="hello", persistTo=" ZERO " );

            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.set( id="unittest", value="hello", persistTo="ZERO" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.set( id="unittest", value="hello", persistTo="MASTER" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.set( id="unittest", value="hello", persistTo="ONE" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

          });

          it( "with valid replicateTo", function(){
            var cas = 0;
            // Extra whitespace
            var doc = couchbase.set( id="unittest", value="hello", replicateTo=" ZERO " );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.set( id="unittest", value="hello", replicateTo="ZERO" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

          });

        });




      });


      /**************************************************************/
      /**************** replace *************************************/
      /**************************************************************/
      describe( "replace operations", function(){
        it( "will replace a document", function(){
          couchbase.set( id="replaceMe", value="whatever" );
          var doc = couchbase.getWithCAS( id="replaceMe" );
          var result = couchbase.replace( id="replaceMe", value="new value", cas=doc.cas, timeout=1 );
          expect( result ).toBe( true );

          var doc = couchbase.get( id="replaceMe");
          expect( doc ).toBe( "new value" );

          var result = couchbase.replace( id=createUUID(), value="Not gonna' exist", cas=0, timeout=1 );
          expect( result ).toBe( false );
        });
      });

      /**************************************************************/
      /**************** get operations ******************************/
      /**************************************************************/
      describe( "get operations", function(){

        it( "of a valid object", function(){
          var data = now();
          couchbase.set( id="unittest", value=data );
          expect( couchbase.get( "unittest" ) ).toBe( data );
        });

        it( "of an invalid object", function(){
          expect( couchbase.get( "Nothing123" ) ).toBeNull();
        });

        it( "of a valid object with CAS", function(){
          var data = now();
          couchbase.set( id="unittest", value=data );

          var result = couchbase.getWithCAS( "unittest" );

          expect( result.CAS ).toBeNumeric();
          expect( result.value ).toBe( data );

        });

        it( "of an invalid object with CAS", function(){
          expect( couchbase.get( "Nothing123" ) ).toBeNull();
        });

        it( "of a valid object with touch", function(){
          var data = now();
          // Set with 5 minute timeout
          couchbase.set( id="unittest-touch", value=data, timeout=5 );
          var doc = couchbase.getWithCAS( id="unittest-touch" );

          var original_exptime = doc.expiry;

          // Touch with 10 minute timeout
          var result = couchbase.getAndTouch( "unittest-touch", 10 );

          expect( result.CAS ).toBeNumeric();
          expect( result.value ).toBe( data );

          // The timeout should now be 5 minutes farther in the future
          expect( result.expiry > original_exptime ).toBeTrue();

        });

        it( "of an invalid object with touch", function(){
          expect( couchbase.getAndTouch( "Nothing123", 10 ) ).toBeNull();
        });

        it( "with case-insensitive IDs", function(){
          var data = now();
          couchbase.set( id="myid ", value=data );
          expect( couchbase.get( "MYID" ) ).toBe( data );
        });

        it( "with multiple IDs", function(){
          couchbase.set( id="ID1", value="value1" );
          couchbase.set( id="ID2", value="value2" );
          couchbase.set( id="ID3", value="value3" );

          var result = couchbase.getMulti( ["ID1","ID2","ID3","not_existant"] );

          expect( result.id1 ).toBe( "value1" );
          expect( result.id2 ).toBe( "value2" );
          expect( result.id3 ).toBe( "value3" );

          expect( result ).notToHaveKey( "not_existant" );
        });

      });


      /**************************************************************/
      /**************** add operations ******************************/
      /**************************************************************/
      describe( "add operations", function(){
        it( "will only add once", function(){
          var data = now();
          var randID = createUUID();
          var result = couchbase.add( id=randID, value=data, timeout=1 );

          expect( result ).toBe( true );
          expect( couchbase.get( randID ) ).toBe( data );

          var result = couchbase.add( id=randID, value=data, timeout=1 );

          expect( result ).toBe( false );
        });
      });

      /**************************************************************/
      /**************** delete operations ***************************/
      /**************************************************************/
      describe( "delete operations", function(){

        it( "of an invalid document", function(){
          var result = couchbase.delete( id="invalid-doc" );
          expect( result ).toBeFalse();
        });

        it( "of a valid document", function(){
          couchbase.set( id="unittest", value="hello" );

          var result = couchbase.delete( id="unittest" );
          expect( result ).toBeTrue();
        });

        it( "of multiple documents", function(){
          var data = { "data1" = "null", "data2"= "luis majano" };
          couchbase.setMulti( data=data );

          var results = couchbase.delete( id=[ "data1", "data2" ] );
          for( var key in results ){
            expect( results[key] ).toBeTrue();
          }
        });

      });

      /**************************************************************/
      /**************** append/prepend operations ****************************/
      /**************************************************************/
      describe( "append+prepend operations", function(){

        it( "can append", function(){
          couchbase.set( id="append-test1", value="Hello" );
          couchbase.append( id="append-test1", value=" Luis" );

          var value = couchbase.get( "append-test1" );
          expect( value ).toBe( "Hello Luis" );

        });

        it( "can append with CAS", function(){
          var doc = couchbase.set( id="append-test2", value="Hello" );
          couchbase.append( id="append-test2", value=" Luis Majano", cas=doc.cas );

          var value = couchbase.get( "append-test2" );
          expect( value ).toBe( "Hello Luis Majano" );
        });

        it( "can prepend", function(){
          couchbase.set( id="prepend-test1", value="Hello" );
          couchbase.prepend( id="prepend-test1", value="Hola and " );

          var value = couchbase.get( "prepend-test1" );
          expect( value ).toBe( "Hola and Hello" );

        });

        it( "can prepend with CAS", function(){
          var doc = couchbase.set( id="prepend-test2", value="Luis" );
          couchbase.prepend( id="prepend-test2", value="Hola ", cas=doc.cas );

          var value = couchbase.get( "prepend-test2" );
          expect( value ).toBe( "Hola Luis" );
        });

      });

    });
  }

}