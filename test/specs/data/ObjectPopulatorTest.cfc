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
component extends="testbox.system.BaseSpec"{

/*********************************** LIFE CYCLE Methods ***********************************/

  function beforeAll(){
    variables.OP = new cfcouchbase.data.ObjectPopulator();

    variables.data = {
      firstname = "Brad",
      lastName = "Wood",
      age = "33",
      id = 1,
      createdDate = now(),
      updatedDate = now()
    };
  }

  function afterAll(){
  }

/*********************************** BDD SUITES ***********************************/

  function run(){
    describe( "The Object Populator", function(){

      it( "can populate a simple object with JSON", function(){
        var userSimple = new test.resources.UserSimple();

        variables.OP.populateFromJSON( userSimple, serializeJSON( variables.data ) );

        expect( userSimple.getFirstname() ).toBe( variables.data.firstname );
        expect( userSimple.getLastName() ).toBe( variables.data.lastName );
        expect( userSimple.getAge() ).toBe( variables.data.age );
        expect( userSimple.getID() ).toBe( variables.data.id );
        expect( userSimple.getCreatedDate() ).toBe( variables.data.createdDate );
        expect( userSimple.getUpdatedDate() ).toBe( variables.data.updatedDate );

      });

      it( "can populate a simple object with struct", function(){
        var userSimple = new test.resources.UserSimple();

        variables.OP.populateFromStruct( userSimple, variables.data );

        expect( userSimple.getFirstname() ).toBe( variables.data.firstname );
        expect( userSimple.getLastName() ).toBe( variables.data.lastName );
        expect( userSimple.getAge() ).toBe( variables.data.age );
        expect( userSimple.getID() ).toBe( variables.data.id );
        expect( userSimple.getCreatedDate() ).toBe( variables.data.createdDate );
        expect( userSimple.getUpdatedDate() ).toBe( variables.data.updatedDate );

      });

      it( "can populate a simple object with scope injection", function(){
        var userSimple = new test.resources.UserSimple();

        variables.OP.populateFromStruct( userSimple, variables.data, "variables" );

        expect( userSimple.getFirstname() ).toBe( variables.data.firstname );
        expect( userSimple.getLastName() ).toBe( variables.data.lastName );
        expect( userSimple.getAge() ).toBe( variables.data.age );
        expect( userSimple.getID() ).toBe( variables.data.id );
        expect( userSimple.getCreatedDate() ).toBe( variables.data.createdDate );
        expect( userSimple.getUpdatedDate() ).toBe( variables.data.updatedDate );

      });

      it( "can populate a only certain columns", function(){
        var userSimple = new test.resources.UserSimple();

        variables.OP.populateFromStruct( target = userSimple, memento = variables.data, include = 'firstName');

        expect( userSimple.getFirstname() ).toBe( variables.data.firstname );
        expect( userSimple.getLastName() ).toBeEmpty();

      });

      it( "can populate a everything but certain columns", function(){
        var userSimple = new test.resources.UserSimple();

        variables.OP.populateFromStruct( target = userSimple, memento = variables.data, exclude = 'firstName');

        expect( userSimple.getFirstname() ).toBeEmpty();
        expect( userSimple.getLastName() ).toBe( variables.data.lastname );

      });

    });
  }

}