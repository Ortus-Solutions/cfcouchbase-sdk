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
    util = couchbase.getUtil();
  }

  function afterAll(){
    couchbase.shutdown( 10 );
  }

/*********************************** BDD SUITES ***********************************/

  function run(){
    describe( "SDK Utility", function(){

      describe( "dataType operations", function(){

        it( "can determine a struct", function(){
          var data = {
            "name": "Aaron"
          };
          expect( util.getDataType(data) ).toBe( "struct" );
        });

        it( "can determine an array", function(){
          var data = [ "Aaron" ];
          expect( util.getDataType(data) ).toBe( "array" );
        });

        it( "can determine a double", function(){
          var data = 57.93;
          expect( util.getDataType(data) ).toBe( "double" );
        });

        it( "can determine a long", function(){
          var data = 2398734;
          expect( util.getDataType(data) ).toBe( "long" );
        });

        it( "can determine an object", function(){
          var data = new tests.resources.User();
          expect( util.getDataType(data) ).toBe( "object" );
        });

        it( "can determine a binary", function(){
          var data = toBinary( toBase64( "Aaron" ) );
          expect( util.getDataType(data) ).toBe( "binary" );
        });

        it( "can determine a boolean", function(){
          var data = true;
          expect( util.getDataType(data) ).toBe( "boolean" );
        });

        it( "can determine a string", function(){
          var data = "Aaron";
          expect( util.getDataType(data) ).toBe( "string" );
        });

        it( "can convert IDs to lowercase", function(){
          var id = "TeSt";
          expect( hash( util.normalizeID( id ) ) ).toBe( hash( "test" ) );
        });

        it( "can convert an array of IDs to lowercase", function(){
          var id = [ "KeY1", "kEy2" ];
          expect( hash( arrayToList( util.normalizeID( id ) ) ) ).toBe( hash( "key1,key2" ) );
        });

        it( "can maintain ID case", function(){
          var id = "TeSt";
          expect( hash( util.normalizeID( id ) ) ).toBe( hash( "test" ) );
        });

        it( "can convert an array of IDs to lowercase", function(){
          var id = [ "KeY1", "kEy2" ];
          expect( hash( arrayToList( util.normalizeID( id ) ) ) ).toBe( hash( "key1,key2" ) );
        });

      });

    });
  }

}
