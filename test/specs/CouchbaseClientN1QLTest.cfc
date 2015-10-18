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
    couchbase = new cfcouchbase.CouchbaseClient( { bucketName="travel-sample" } );
  }

  function afterAll(){
    couchbase.shutdown( 10 );
  }

/*********************************** BDD SUITES ***********************************/

  function run(){
    describe( "N1QL Query Operations", function(){

      it( "can perform a simple statement query", function(){
        var data = couchbase.n1qlQuery("
          SELECT *
          FROM `travel-sample`
          LIMIT 1
        ");

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "results" );
        expect( data.results ).toBeArray();
        expect( arrayLen( data.results ) ).toBe( 1 );
      });

      it( "can perform a positional parameterized query", function(){
        var data = couchbase.n1qlQuery(
          statement="
            SELECT callsign, country, iata, icao, id, name, type
            FROM `travel-sample`
            WHERE icao = $1
          ",
          parameters=["MLA"]
        );

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "results" );
        expect( data.results ).toBeArray();
        expect( arrayLen( data.results ) ).toBe( 1 );
        expect( data.results[1].icao ).toBe ( "MLA" );
      });

      it( "can perform a named parameterized query", function(){
        var data = couchbase.n1qlQuery(
          statement="
            SELECT airportname, city, country, faa, geo, icao, id, type, tz
            FROM `travel-sample`
            WHERE city = $city
            LIMIT 1
          ",
          parameters={
            'city' = "London"
          }
        );

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "results" );
        expect( data.results ).toBeArray();
        expect( arrayLen( data.results ) ).toBe( 1 );
        expect( data.results[1].city ).toBe ( "London" );
      });

      it( "can query without an index", function(){
        var data = couchbase.n1qlQuery("
          SELECT callsign, country, iata, icao, id, name, type
          FROM `travel-sample`
          WHERE id = 10
        ");
        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "results" );
        expect( data.results ).toBeArray();
        expect( arrayLen( data.results ) ).toBe( 1 );
        expect( data.results[1].id ).toBe( 10 );
      });

      it( "can insert values", function(){
        var data = couchbase.n1qlQuery('
          INSERT INTO default ( KEY, VALUE )
          VALUES ( "insert-test-' & createUUID() & '", {
            "first_name": "Aaron",
            "last_name": "Benton"
          } )
          RETURNING *
        ');

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "results" );
        expect( arrayLen( data.results ) ).toBe( 1 );
        expect( data ).toHaveKey( "metrics" );
        expect( data.metrics.mutationCount ).toBe( 1 );
      });

      it( "can update values", function(){
        // add the value so we can update it
        var key = "update-test-" & createUUID();
        var data = couchbase.n1qlQuery('
          INSERT INTO default ( KEY, VALUE )
          VALUES ( "' & key & '", {
            "first_name": "Aaron",
            "last_name": "Benton"
          } )
          RETURNING *
        ');
        var data = couchbase.n1qlQuery('
          UPDATE default
          USE KEYS "' & key & '"
          SET first_name = "Luis",
              last_name = "Majano"
          RETURNING default.first_name, default.last_name
        ');

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "results" );
        expect( arrayLen( data.results ) ).toBe( 1 );
        expect( data ).toHaveKey( "metrics" );
        expect( data.metrics.mutationCount ).toBe( 1 );
      });

      it( "can delete documents", function(){
        var data = couchbase.n1qlQuery('
          INSERT INTO default ( KEY, VALUE )
          VALUES ( "delete-test", "delete me" )
        ');
        var data = couchbase.n1qlQuery('
          DELETE
          FROM default
          USE KEYS "delete-test"
        ');

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "metrics" );
        expect( data.metrics.mutationCount ).toBe( 1 );
      });

      it( "can return a clientContextId", function(){
        var queryId = createUUID();
        var data = couchbase.n1qlQuery(
          statement="
            SELECT *
            FROM `travel-sample`
            LIMIT 1
          ",
          options={
            'clientContextId' = queryId
          }
        );

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "clientContextId" );
        expect( data.clientContextId ).toBe( queryId );
      });

      it( "can return a valid requestId", function(){
        var queryId = createUUID();
        var data = couchbase.n1qlQuery("
          SELECT *
          FROM `travel-sample`
          LIMIT 1
        ");

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "requestId" );
        expect( len( data.requestId ) > 0 ).toBeTrue();
      });

      it( "can return metrics", function(){
        // invalid SQL statement because table names with dashes
        // must be escaped with back ticks
        var data = couchbase.n1qlQuery("
          SELECT *
          FROM `travel-sample`
          LIMIT 1
        ");

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "metrics" );
        expect( structCount( data.metrics ) ).toBeGTE( 4 );
      });

      it( "can handle errors", function(){
        // invalid SQL statement because table names with dashes
        // must be escaped with back ticks
        var data = couchbase.n1qlQuery("
          SELECT *
          FROM travel-sample
          LIMIT 1
        ");

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "errors" );
        expect( arrayLen( data.errors ) ).toBe( 1 );
        expect( data.errors[1].code ).toBe( 3000 );
        expect( data ).toHaveKey( "success" );
        expect( data.success ).toBeFalse();
      });

      it( "can invalid query cache", function(){
        var entries = couchbase.invalidateQueryCache();
        expect( entries ).toBeNumeric();
      });

      it( "can query with options", function(){
        var data = couchbase.n1qlQuery(
          statement="
            SELECT *
            FROM `travel-sample`
            LIMIT 1
          ",
          options={
            adhoc = true,
            consistency = "STATEMENT_PLUS",
            maxParallelism = 2,
            scanWait = 2500,
            serverSideTimeout = 2500,
            clientContextId = createUUID()
          }
        );

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "results" );
        expect( data.results ).toBeArray();
        expect( arrayLen( data.results ) ).toBe( 1 );
      });

      it( "can do a query with a filter", function(){
        var data = couchbase.n1qlQuery(
          statement='
            SELECT callsign, country, iata, icao, id, name, type
            FROM `travel-sample`
            WHERE type = "airline"
          ',
          filter=function( row ){
            return false;
          }
        );

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "results" );
        expect( data.results ).toBeArray();
        expect( arrayLen( data.results ) ).toBe( 0 );
      });

      it( "can do a non-deserialized query", function(){
        var data = couchbase.n1qlQuery(
          statement='
            SELECT callsign, country, iata, icao, id, name, type
            FROM `travel-sample`
            WHERE type = "airline"
          ',
          deserialize = false
        );

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "results" );
        expect( data.results ).toBeArray();
        expect( arrayLen( data.results ) ).toBeGT( 0 );
        expect( data.results[ 1 ] ).toBeString();
      });

      it( "can do a paginated query", function(){
        var data = couchbase.n1qlQuery('
          SELECT DISTINCT(type)
          FROM `travel-sample`
          ORDER BY type ASC
          LIMIT 1
          OFFSET 2
        ');

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "results" );
        expect( data.results ).toBeArray();
        expect( arrayLen( data.results ) ).toBe( 1 );
        expect( data.results[ 1 ].type ).toBe( "airport" );
      });

      it( "can do a query with custom transformations", function(){
        var data = couchbase.n1qlQuery(
          statement='
            SELECT callsign, country, iata, icao, id, name, type
            FROM `travel-sample`
            WHERE type = "airline"
            LIMIT 10
          ',
          deserialize = false,
          transform=function( row ){
            return deserializeJSON( arguments.row );
          }
        );

        expect( data ).toBeStruct();
        expect( data ).toHaveKey( "results" );
        expect( data.results ).toBeArray();
        expect( arrayLen( data.results ) ).toBeGT( 0 );
        expect( data.results[ 1 ] ).notToBeString();
      });

      it( "can return native results", function(){
        var data = couchbase.n1qlQuery(
          statement='
            SELECT callsign, country, iata, icao, id, name, type
            FROM `travel-sample`
            WHERE type = "airline"
            LIMIT 10
          ',
          returnType = "native"
        );
        expect( data.getClass().getName() ).toBe( "com.couchbase.client.java.query.DefaultN1qlQueryResult" );
      });

      it( "can return a native iterator", function(){
        var data = couchbase.n1qlQuery(
          statement='
            SELECT callsign, country, iata, icao, id, name, type
            FROM `travel-sample`
            WHERE type = "airline"
            LIMIT 10
          ',
          returnType = "iterator"
        );
        var row = data.next();
        expect( row.getClass().getName() ).toBe( "com.couchbase.client.java.query.DefaultN1qlQueryRow" );
        expect( row.value().getClass().getName() ).toBe( "com.couchbase.client.java.document.json.JsonObject" );
      });

      it( "can throw on invalid adhoc", function(){
        expect(function(){
          couchbase.n1qlQuery(
            statement="SELECT * FROM `travel-sample` LIMIT 1",
            options={
              'adhoc' = "invalid"
            }
          );
        }).toThrow( type="CouchbaseClient.N1qlParam.AdhocException" );
      });

      it( "can throw on invalid consistency", function(){
        expect(function(){
          couchbase.n1qlQuery(
            statement="SELECT * FROM `travel-sample` LIMIT 1",
            options={
              'consistency' = "invalid"
            }
          );
        }).toThrow( type="CouchbaseClient.N1qlParam.ConsistencyException" );
      });

      it( "can throw on invalid maxParallelism", function(){
        expect(function(){
          couchbase.n1qlQuery(
            statement="SELECT * FROM `travel-sample` LIMIT 1",
            options={
              'maxParallelism' = "invalid"
            }
          );
        }).toThrow( type="CouchbaseClient.N1qlParam.MaxParallelismException" );
      });

      it( "can throw on invalid scanWait", function(){
        expect(function(){
          couchbase.n1qlQuery(
            statement="SELECT * FROM `travel-sample` LIMIT 1",
            options={
              'scanWait' = "invalid"
            }
          );
        }).toThrow( type="CouchbaseClient.N1qlParam.ScanWaitException" );
      });

      it( "can throw on invalid serverSideTimeout", function(){
        expect(function(){
          couchbase.n1qlQuery(
            statement="SELECT * FROM `travel-sample` LIMIT 1",
            options={
              'serverSideTimeout' = "invalid"
            }
          );
        }).toThrow( type="CouchbaseClient.N1qlParam.ServerSideTimeoutException" );
      });

      it( "can throw on invalid clientContextId", function(){
        expect(function(){
          couchbase.n1qlQuery(
            statement="SELECT * FROM `travel-sample` LIMIT 1",
            options={
              'clientContextId' = [ "invalid" ]
            }
          );
        }).toThrow( type="CouchbaseClient.N1qlParam.ClientContextIdException" );
      });

      it( "can create index", function(){
        var index = couchbase.n1qlQuery("
          CREATE INDEX `idx_beer_sample_type` ON `beer-sample` (type) USING GSI
        ");

        expect( index ).toBeStruct();
        expect( index ).toHaveKey( "success" );
        expect( index.success ).toBeTrue();

        var check = couchbase.n1qlQuery("
          SELECT datastore_id, id, index_key, keyspace_id, name, namespace_id, state, `using`
          FROM system:indexes
          WHERE name = 'idx_beer_sample_type'
        ");

        expect( check ).toBeStruct();
        expect( check ).toHaveKey( "results" );
        expect( arrayLen( check.results ) ).toBeGT( 0 );
        expect( check.results[ 1 ].name ).toBe( "idx_beer_sample_type" );
      });

      it( "can drop index", function(){
        var index = couchbase.n1qlQuery("
          DROP INDEX `beer-sample`.`idx_beer_sample_type` USING GSI
        ");
        var check = couchbase.n1qlQuery("
          SELECT datastore_id, id, index_key, keyspace_id, name, namespace_id, state, `using`
          FROM system:indexes
          WHERE name = 'idx_beer_sample_type'
        ");

        expect( index ).toBeStruct();
        expect( index ).toHaveKey( "success" );
        expect( index.success ).toBeTrue();

        expect( check ).toBeStruct();
        expect( check ).toHaveKey( "results" );
        expect( arrayLen( check.results ) ).toBe( 0 );
      });

      it( "can defer the build of an index", function(){
        // drop the index first since it will fail after the first test otherwise
        couchbase.n1qlQuery("
          DROP INDEX `beer-sample`.`idx_beer_sample_test` USING GSI
        ");
        var index = couchbase.n1qlQuery('
          CREATE INDEX `idx_beer_sample_test` ON `beer-sample` (type) USING GSI
          WITH {"defer_build": true}
        ');
        debug(index);
        expect( index ).toBeStruct();
        expect( index ).toHaveKey( "success" );
        expect( index.success ).toBeTrue();

        var check = couchbase.n1qlQuery("
          SELECT datastore_id, id, index_key, keyspace_id, name, namespace_id, state, `using`
          FROM system:indexes
          WHERE name = 'idx_beer_sample_test'
        ");

        expect( check ).toBeStruct();
        expect( check ).toHaveKey( "results" );
        expect( arrayLen( check.results ) ).toBeGT( 0 );
        expect( check.results[ 1 ].state ).toBe( "pending" );

        var build = couchbase.n1qlQuery('
          BUILD INDEX ON `beer-sample` (`idx_beer_sample_test`) USING GSI
        ');
        debug(build);
        expect( build ).toBeStruct();
        expect( build ).toHaveKey( "success" );
        expect( build.success ).toBeTrue();

        var buildCheck = couchbase.n1qlQuery("
          SELECT datastore_id, id, index_key, keyspace_id, name, namespace_id, state, `using`
          FROM system:indexes
          WHERE name = 'idx_beer_sample_test'
        ");
        debug(buildCheck);
        expect( buildCheck ).toBeStruct();
        expect( buildCheck ).toHaveKey( "results" );
        expect( arrayLen( buildCheck.results ) ).toBeGT( 0 );
        expect( buildCheck.results[ 1 ].state ).toBe( "pending" );
      });

      it( "can get all of the system indexes", function(){
        var indexes = couchbase.getIndexes( "travel-sample" );

        expect( indexes ).toBeArray();
        expect( arrayLen( index ) ).toBeGT( 0 );
      });

      it( "can produce a raw query object", function(){
        var oQuery = couchbase.newN1qlQuery("
          SELECT *
          FROM `travel-sample`
          LIMIT 1
        ");

        expect( oQuery.getClass().getName() ).toBe( "com.couchbase.client.java.query.SimpleN1qlQuery" );
      });

      it( "can produce a raw query object with options", function(){
        var oQuery = couchbase.newN1qlQuery(
          statement="
            SELECT *
            FROM `travel-sample`
            LIMIT 1
          ",
          options={
            adhoc = true,
            consistency = "STATEMENT_PLUS",
            maxParallelism = 2,
            scanWait = 2500,
            serverSideTimeout = 2500,
            clientContextId = "client-id"
          }
        );
        expect( oQuery.getClass().getName() ).toBe( "com.couchbase.client.java.query.SimpleN1qlQuery" );
        // there are not getting methods for values that have been set but we can verify the values
        // set by calling the toString() method of the N1qlQuery.params() object
        expect( oQuery.params().toString() ).toBe( "N1qlParams{serverSideTimeout='2500ms', consistency=STATEMENT_PLUS, scanWait='2500ms', clientContextId='client-id', maxParallelism=2, adhoc=true}" );
      });

      it( "can do a raw query", function(){
        var oQuery = couchbase.newN1qlQuery(
          statement="
            SELECT *
            FROM `travel-sample`
            LIMIT 1
          "
        );
        var results = couchbase.rawQuery( oQuery );

        expect( results.finalSuccess() ).toBeTrue();
      });

    });

  }

}