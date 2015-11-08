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

      xit( "can flush docs", function(){
        couchbase.flush();

        expect( couchbase.getAggregateStat( "Administrator", "password", "curr_items" ) ).toBeNumeric();
      } );

      it( "can touch an expiration time", function(){
        couchbase.upsert( id="touch-test", value="value", timeout=10 );
        var touch = couchbase.touch( id="touch-test", timeout=0 );
        expect( touch ).toBeTrue();
      } );

      it( "can get available servers", function(){
        var servers = couchbase.getAvailableServers( "Administrator", "password" );
        expect( arrayLen( servers ) ).toBeGTE( 1 );
      } );

      it( "can get unavailable servers", function(){
        var servers = couchbase.getUnAvailableServers( "Administrator", "password" );
        expect( arrayLen( servers ) ).toBe( 0 );
      } );

      it( "can get the environment", function(){
        var env = couchbase.getEnvironment();
        expect( env ).toBeStruct();
        expect( env ).toHaveKey( "kvTimeout" );
        expect( env.kvTimeout ).toBeNumeric();
      } );

      /**************************************************************/
      /**************** set operations ******************************/
      /**************************************************************/
      describe( "set operations", function(){

        it( "with just ID and value", function(){
          var key = "unittest";
          var doc = couchbase.upsert( id="unittest", value="hello" );

          expect( doc ).toBeStruct();
          expect( doc ).toHaveKey( "id" );
          expect( doc ).toHaveKey( "cas" );
          expect( doc ).toHaveKey( "expiry" );
          expect( doc ).toHaveKey( "hashCode" );
          expect( doc.id ).toBe( key );
        } );

        it( "with invalid timeout", function(){
            expect( function(){
              couchbase.upsert( id="unittest", value="hello", timeout=-5 );
            })
            .toThrow( type="InvalidTimeout" );
        } );

        it( "with valid timeout", function(){
          var key = "unittest";
          var doc = couchbase.upsert( id=key, value=key, timeout=5 );

          expect( doc ).toBeStruct();
          expect( doc ).toHaveKey( "id" );
          expect( doc ).toHaveKey( "cas" );
          expect( doc ).toHaveKey( "expiry" );
          expect( doc ).toHaveKey( "hashCode" );
          expect( doc.id ).toBe( key );
        } );

        it( "with timeout less than 30 days", function(){
          couchbase.upsert( id="ten_minutes", value="I should only last 10 minutes", timeout=10 );
          var doc = couchbase.getWithCAS( id="ten_minutes" );

          var currentEpochDate = createObject("java","java.util.Date").init().getTime() / 1000;
          var tenMinutesInTheFutureEpoch = round(currentEpochDate + (10 * 60));

          // See if the expiration date (stored as seconds since epoch) matches what I think it should be.
          //  Just make sure the values are within 10 seconds since I don't know the exact timing of the put() call.
          expect( round(tenMinutesInTheFutureEpoch/100) )
            .toBeCloseTo( round( doc[ "expiry" ]/100 ), 50 );

        } );

        it( "with timeout greater than 30 days", function(){
          couchbase.upsert( id="fortyFive_days", value="I should last 45 days", timeout=45*24*60 );
          var currentEpochDate = createObject( "java", "java.util.Date" ).init().getTime() / 1000;
          var fortyFiveDaysInTheFutureEpoch = round( currentEpochDate + ( 45 * 60 * 60 * 24 ) );
          var doc = couchbase.getWithCas( id="fortyFive_days" );
          // See if the expiration date (stored as seconds since epoch) matches what I think it should be.
          //  Just make sure the values are within 10 seconds since I don't know the exact timing of the put() call.
          expect( round( fortyFiveDaysInTheFutureEpoch / 100 ) )
            .toBeCloseTo( round( doc.expiry / 100 ), 50 );

        } );

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
          var doc = couchbase.upsert( id=key, value=data );

          expect( doc ).toBeStruct();
          expect( doc ).toHaveKey( "id" );
          expect( doc ).toHaveKey( "cas" );
          expect( doc ).toHaveKey( "expiry" );
          expect( doc ).toHaveKey( "hashCode" );
          expect( doc.id ).toBe( key );
        } );

        it( "can decrement values", function(){
          couchbase.upsert( id="unit-decrement", value=10 );
          var result = couchbase.counter( "unit-decrement", -1 );
          expect( result ).toBe( 9 );
        } );

        it( "can decrement values asynchronously", function(){
          expect( function(){
            couchbase.asyncCounter( "unit-decrement", -1 )
          })
          .toThrow( type="CouchbaseClient.NotSupported" );
        } );

        it( "can increment values", function(){
          couchbase.upsert( id="unit-increment", value="10" );
          var result = couchbase.counter( "unit-increment", 10 );
          expect( result ).toBe( 20 );
        } );

        it( "can increment values asynchronously", function(){
          expect( function(){
            couchbase.asyncCounter( "unit-increment", 1 )
          })
          .toThrow( type="CouchbaseClient.NotSupported" );
        } );

        it( "will set multiple documents", function(){
          var data = {
            "id1"="value1",
            "id2"="value2",
            "id3"="value3"
          };
          var futures = couchbase.setMulti( data=data, timeout=1 );

          expect( futures ).toBeStruct();

          expect( futures ).toHaveKey( "id1" );
          expect( futures ).toHaveKey( "id2" );
          expect( futures ).toHaveKey( "id3" );

          expect( couchbase.get( "id1" ) ).toBe( "value1" );
          expect( couchbase.get( "id2" ) ).toBe( "value2" );
          expect( couchbase.get( "id3" ) ).toBe( "value3" );
        } );


        it( "with CAS value that hasn't changed", function(){
          couchbase.upsert( id="unittest", value="hello" );
          var getResult = couchbase.getWithCAS( id="unittest" );
          var setResult = couchbase.setWithCAS( id="unittest", cas=getResult.cas, value="New Value" );

          expect( setResult ).toBeStruct();
          expect( setResult ).toHaveKey( "status" );
          expect( setResult ).toHaveKey( "detail" );
          expect( setResult.status ).toBe( true );
          expect( setResult.detail ).toBe( "SUCCESS" );
        } );

        it( "with CAS value that is out-of-date", function(){
          couchbase.upsert( id="unittest", value="hello" );
          var getResult = couchbase.getWithCAS( id="unittest" );
          couchbase.upsert( id="unittest", value="a new value" );
          var setResult = couchbase.setWithCAS( id="unittest", cas=getResult.cas, value="New Value" );

          expect( setResult ).toBeStruct();
          expect( setResult ).toHaveKey( "status" );
          expect( setResult ).toHaveKey( "detail" );
          expect( setResult.status ).toBe( false );
          expect( setResult.detail ).toBe( "CAS_CHANGED" );
        } );

        it( "with CAS value and key that doesn't exist", function(){
          var setResult = couchbase.setWithCAS( id=createUUID(), cas=123456789, value="New Value" );

          expect( setResult ).toBeStruct();
          expect( setResult ).toHaveKey( "status" );
          expect( setResult ).toHaveKey( "detail" );
          expect( setResult.status ).toBe( false );
          expect( setResult.detail ).toBe( "NOT_FOUND" );
        } );


        describe( "Durability Options", function() {

          it( "with default persisTo and replicateTo", function(){
            var key = "unittest";
            var doc = couchbase.upsert( id=key, value="hello" );

            expect( doc ).toBeStruct();
            expect( doc ).toHaveKey( "id" );
            expect( doc ).toHaveKey( "cas" );
            expect( doc ).toHaveKey( "expiry" );
            expect( doc ).toHaveKey( "hashCode" );
            expect( doc.id ).toBe( key );
          } );

          it( "with invalid persisTo", function(){
            expect( function(){
              couchbase.upsert( id="unittest", value="hello", persistTo="invalid" );
                  }).toThrow( type="InvalidPersistTo" );
          } );

          it( "with invalid replicateTo", function(){
            expect( function(){
              couchbase.upsert( id="unittest", value="hello", replicateTo="invalid" );
                  }).toThrow( type="InvalidReplicateTo" );
          } );

          it( "with valid persisTo", function(){
            var cas = 0;
            // Extra whitespace
            var doc = couchbase.upsert( id="unittest", value="hello", persistTo=" ZERO " );

            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.upsert( id="unittest", value="hello", persistTo="ZERO" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.upsert( id="unittest", value="hello", persistTo="MASTER" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.upsert( id="unittest", value="hello", persistTo="ONE" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

          } );

          it( "with valid replicateTo", function(){
            var cas = 0;
            // Extra whitespace
            var doc = couchbase.upsert( id="unittest", value="hello", replicateTo=" ZERO " );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.upsert( id="unittest", value="hello", replicateTo="ZERO" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

          } );

        } );

      } );


      /**************************************************************/
      /**************** replace *************************************/
      /**************************************************************/
      describe( "replace operations", function(){
        it( "will replace a document", function(){
          couchbase.upsert( id="replaceMe", value="whatever" );
          var doc = couchbase.getWithCAS( id="replaceMe" );
          var result = couchbase.replace( id="replaceMe", value="new value", cas=doc.cas, timeout=1 );
          expect( result ).toBe( true );

          var doc = couchbase.get( id="replaceMe");
          expect( doc ).toBe( "new value" );

          var result = couchbase.replace( id=createUUID(), value="Not gonna' exist", cas=0, timeout=1 );
          expect( result ).toBe( false );
        } );
      } );

      /**************************************************************/
      /**************** get operations ******************************/
      /**************************************************************/
      describe( "get operations", function(){

        it( "of a valid object", function(){
          var data = now();
          couchbase.upsert( id="unittest", value=data );
          expect( couchbase.get( "unittest" ) ).toBe( data );
        } );

        it( "of an invalid object", function(){
          expect( couchbase.get( "Nothing123" ) ).toBeNull();
        } );

        it( "of a valid object with CAS", function(){
          var data = now();
          couchbase.upsert( id="unittest", value=data );

          var result = couchbase.getWithCAS( "unittest" );

          expect( result.CAS ).toBeNumeric();
          expect( result.value ).toBe( data );

        } );

        it( "of an invalid object with CAS", function(){
          expect( couchbase.get( "Nothing123" ) ).toBeNull();
        } );

        it( "of a valid object with touch", function(){
          var data = now();
          // Set with 5 minute timeout
          couchbase.upsert( id="unittest-touch", value=data, timeout=5 );
          var doc = couchbase.getWithCAS( id="unittest-touch" );

          var original_exptime = doc.expiry;

          // Touch with 10 minute timeout
          var result = couchbase.getAndTouch( "unittest-touch", 10 );

          expect( result.cas ).toBeNumeric();
          expect( result.value ).toBe( data );

          // The timeout should now be 5 minutes farther in the future
          expect( result.expiry > original_exptime ).toBeTrue();

        } );

        it( "of an invalid object with touch", function(){
          expect( couchbase.getAndTouch( "Nothing123", 10 ) ).toBeNull();
        } );

        it( "with case-insensitive IDs", function(){
          var data = now();
          couchbase.upsert( id="myid ", value=data );
          expect( couchbase.get( "MYID" ) ).toBe( data );
        } );

        it( "with multiple IDs", function(){
          couchbase.upsert( ID="ID1", value="value1" );
          couchbase.upsert( ID="ID2", value="value2" );
          couchbase.upsert( ID="ID3", value="value3" );

          var result = couchbase.getMulti( ["ID1","ID2","ID3","not_existant"] );

          expect( result.id1 ).toBe( "value1" );
          expect( result.id2 ).toBe( "value2" );
          expect( result.id3 ).toBe( "value3" );

          expect( result ).notToHaveKey( "not_existant" );
        } );

        it( "can determine when an id exists", function(){
          expect( couchbase.exists( "unittest" ) ).toBeTrue();
        } );

        it( "can determine when an id does not exist", function(){
          expect( couchbase.exists( "unittest-does-not-exist" ) ).toBeFalse();
        } );

        it( "can get a document from a replica", function(){
          var replica = couchbase.getFromReplica( id="unittest" );

          expect( replica ).toBeArray();
          expect( arrayLen( replica ) ).toBeGT( 0 );
        } );

        /**************************************************************/
        /**************** async operations ******************************/
        /**************************************************************/
        describe( "that are asynchronous", function(){

          it( "will through with valid object", function(){
            expect( function(){
              var result = couchbase.asyncGet( "ID1" );
            })
            .toThrow( type="CouchbaseClient.NotSupported" );
          });

          it( "with invalid object", function(){
            expect( function(){
              var result = couchbase.asyncGet( "notfound" );
            })
            .toThrow( type="CouchbaseClient.NotSupported" );
          });

          it( "with CAS", function(){
            expect( function(){
              var result = couchbase.asyncGetWithCAS( "ID1" );
            })
            .toThrow( type="CouchbaseClient.NotSupported" );
          });

          it( "with touch", function(){
            expect( function(){
              var result = couchbase.asyncGetAndTouch( "ID1", 5 );
            })
            .toThrow( type="CouchbaseClient.NotSupported" );

          });

          it( "with multiple IDs", function(){
            expect( function(){
              var result = couchbase.asyncGetMulti( [ "ID1", "ID2" ] );
            })
            .toThrow( type="CouchbaseClient.NotSupported" );
          });


        } );

      } );

      /**************************************************************/
      /**************** lock operations ******************************/
      /**************************************************************/
      describe( "lock operations", function(){

        it( "can lock a document", function(){
          var key = "lock-test-" & createUUID();

          couchbase.upsert( id=key, value="lock me" );

          var doc = couchbase.getAndLock( id=key );

          expect( function(){
            couchbase.getAndLock( id=key );
          }).toThrow( type="CouchbaseClient.LockedDocument" );
        } );

        it( "can unlock a document", function(){
          var key = "lock-test-" & createUUID();

          couchbase.upsert( id=key, value="lock me" );

          var doc = couchbase.getAndLock( id=key );

          var unlock = couchbase.unlock( id=key, cas=doc.cas );
          expect( unlock ).toBeTrue();
        } );

        it( "can get a locked document after the lock expires", function(){
          var key = "lock-test-" & createUUID();

          couchbase.upsert( id=key, value="lock me" );

          couchbase.getAndLock( id=key, lockTime=1 );
          sleep(3000);

          var doc = couchbase.getAndLock( id=key );

          expect( doc ).toBeStruct();
          expect( doc ).toHaveKey( "cas" );
          expect( doc.cas ).toBeGT( 0 );
        } );

      } );

      /**************************************************************/
      /**************** insert operations ******************************/
      /**************************************************************/
      describe( "insert operations", function(){
        it( "will only insert once", function(){
          var data = now();
          var randID = createUUID();
          var result = couchbase.insert( id=randID, value=data, timeout=1 );

          expect( result ).toBe( true );
          expect( couchbase.get( randID ) ).toBe( data );

          var result = couchbase.insert( id=randID, value=data, timeout=1 );

          expect( result ).toBe( false );
        } );

        it( "with case-insensitive IDs", function(){
          var data = now();
          couchbase.upsert( id="myid ", value=data );
          expect( couchbase.get( "MYID" ) ).toBe( data );
        } );

        describe( "Durability Options", function() {

          it( "with default persisTo and replicateTo", function(){
            var key = "unittest";
            var doc = couchbase.upsert( id=key, value="hello" );

            expect( doc ).toBeStruct();
            expect( doc ).toHaveKey( "id" );
            expect( doc ).toHaveKey( "cas" );
            expect( doc ).toHaveKey( "expiry" );
            expect( doc ).toHaveKey( "hashCode" );
            expect( doc.id ).toBe( key );
          } );

          it( "with invalid persisTo", function(){
            expect( function(){
              couchbase.upsert( id="unittest", value="hello", persistTo="invalid" );
                  }).toThrow( type="InvalidPersistTo" );
          } );

          it( "with invalid replicateTo", function(){
            expect( function(){
              couchbase.upsert( id="unittest", value="hello", replicateTo="invalid" );
                  }).toThrow( type="InvalidReplicateTo" );
          } );

          it( "with valid persisTo", function(){
            var cas = 0;
            // Extra whitespace
            var doc = couchbase.upsert( id="unittest", value="hello", persistTo=" ZERO " );

            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.upsert( id="unittest", value="hello", persistTo="ZERO" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.upsert( id="unittest", value="hello", persistTo="MASTER" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.upsert( id="unittest", value="hello", persistTo="ONE" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

          } );

          it( "with valid replicateTo", function(){
            var cas = 0;
            // Extra whitespace
            var doc = couchbase.upsert( id="unittest", value="hello", replicateTo=" ZERO " );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

            var doc = couchbase.upsert( id="unittest", value="hello", replicateTo="ZERO" );
            expect( cas ).notToBe( doc.cas );
            cas = doc.cas;

          } );

        } );
      } );

      /**************************************************************/
      /**************** remove operations ***************************/
      /**************************************************************/
      describe( "remove operations", function(){

        it( "of an invalid document", function(){
          var result = couchbase.remove( id="invalid-doc" );
          expect( result ).toBeFalse();
        } );

        it( "of a valid document", function(){
          couchbase.upsert( ID="unittest", value="hello" );

          var result = couchbase.remove( id="unittest" );
          expect( result ).toBeTrue();
        } );

        it( "of multiple documents", function(){
          var data = { "data1" = "null", "data2"= "luis majano" };
          couchbase.upsertMulti( data=data );

          var results = couchbase.remove( id=[ "data1", "data2" ] );
          for( var key in results ){
            expect( results[key] ).toBeTrue();
          }
        } );

      } );

      /**************************************************************/
      /**************** stats operations ****************************/
      /**************************************************************/
      describe( "stats operations", function(){

        it( "can get global stats", function(){
          var stats = couchbase.getStats( "Administrator", "password" );
          expect( stats ).toBeArray();
          expect( couchbase.getAggregateStat( "Administrator", "password", "curr_items" ) ).toBeNumeric();
        } );

        it( "will throw for get doc stats", function(){
          expect( function(){
            couchbase.getDocStats( "unittest" );
          }).toThrow( type="CouchbaseClient.NotSupported" );

        } );

      } );

    } );
  }

}