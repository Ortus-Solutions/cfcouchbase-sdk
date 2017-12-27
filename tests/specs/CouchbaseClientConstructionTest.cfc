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
  }

  function afterAll(){
  }

  /*********************************** BDD SUITES ***********************************/
  function run(){

    describe( "Couchbase Client Construction", function(){

      afterEach(function( currentSpec ){
        couchbase.shutdown();
      });

      it( "with vanilla settings", function(){
        couchbase = new cfcouchbase.CouchbaseClient( config={
          username="cfcouchbase",
          password="password"
        });
        expect( couchbase ).toBeComponent();
      });

      it( "with config struct literal", function(){
        couchbase = new cfcouchbase.CouchbaseClient( config={
          servers="http://127.0.0.1:8091",
          bucketname="default",
          username="cfcouchbase",
          password="password"
        } );
        expect( couchbase ).toBeComponent();
      });

      it( "with config object instance", function(){
        var config = new cfcouchbase.config.CouchbaseConfig(
          bucketName="default",
          viewTimeout="1000",
          username="cfcouchbase",
          password="password"
        );
        couchbase = new cfcouchbase.CouchbaseClient( config=config );
        expect( couchbase ).toBeComponent();
      });

      it( "with config object path", function(){
        couchbase = new cfcouchbase.CouchbaseClient( config="tests.resources.Config" );
        expect( couchbase ).toBeComponent();
      });

      it( "with simple config object", function(){
        var config = new tests.resources.SimpleConfig();
        couchbase = new cfcouchbase.CouchbaseClient( config=config );
        expect( couchbase ).toBeComponent();
        expect( couchbase.getCouchbaseConfig().getDefaultTimeout() ).toBe( 30 );
      });

      it( "with bad config", function(){
        expect( function(){
          var badConfig = new tests.resources.BadConfig();
          couchbase = new cfcouchbase.CouchbaseClient( config=badConfig );
        })
        .toThrow( type="InvalidConfig" );
      });

    });

  }

}
