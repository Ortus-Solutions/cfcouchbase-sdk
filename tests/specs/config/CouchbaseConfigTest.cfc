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
    describe( "Couchbase Config", function(){

      beforeEach(function(){
        config = new cfcouchbase.config.CouchbaseConfig();
        debug( config.getMemento() );
      });

      it( "inits correctly", function(){
        data = config.getMemento();
        expect( data ).toBeStruct();
        expect( data.servers ).toBe( "127.0.0.1" );
      });

      it( "inits with name-value pairs", function(){
        config.init( bucketname="test", password="bogus", dnsSrvEnabled=true );
        expect( config.getBucketname() ).toBe( 'test' );
        expect( config.getPassword() ).toBe( 'bogus' );
        expect( config.getDnsSrvEnabled() ).toBeTrue();
      });

    });
  }

}