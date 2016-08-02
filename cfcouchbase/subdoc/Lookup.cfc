/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>This is the main class used to connect and interact with Couchbase</p>
* @author Luis Majano, Brad Wood, Aaron Benton
*/
component serializable="false" {
  /**
  * The document to perform a SubDoc Lookup Operation on
  */
  property name="id" type="string";
  /**
  * A reference to the connected Couchbase Client
  */
  property name="couchbaseClient" type="CouchbaseClient";

  // Default params, just in case using cf9
  variables['id'] = "";
  variables['couchbaseClient'] = "";
  variables['result'] = {};
  variables['paths'] = [];

  /**
  * Constructor
  * You can pass any name-value pair as arguments to the constructor that matches the properties in this configuration object to be set.
  */
  public function init( required string id, required couchbaseClient) {

    // Check incoming arguments
    for(var thisArg in arguments){
      if(structKeyExists(arguments, thisArg)){
        variables[thisArg] = arguments[thisArg];
      }
    }

    return this;
  }

  public function get( required string path ) {
    arrayAppend( variables.paths, {
      type: 'get',
      value: arguments.path
    } );
    return this;
  }

  public function exists( required string path ) {
    arrayAppend( variables.paths, {
      type: 'exists',
      value: arguments.path
    } );
    return this;
  }

  public function execute() {
    var builder = variables.couchbaseClient.getCouchbaseBucket().lookupIn( variables.id );
    var result = {};
    // build paths
    for( var i = 1; i <= arrayLen(variables.paths); i++ ) {
      builder = builder[variables.paths[i].type]( variables.paths[i].value );
    }
    try {
      // execute
      builder = builder.execute();
      // store the results
      for( var i = 1; i <= arrayLen(variables.paths); i++ ) {
        variables['result'][variables.paths[i].value] = variables.couchbaseClient.deserializeData(
          variables.id,
          builder.content( variables.paths[i].value )
        );
      }
    } catch( any e ) {
      if (e.type == "com.couchbase.client.java.error.DocumentDoesNotExistException" ) { // trap not found exceptions
        variables['result'] = {};
      } else {
        rethrow;
      }
    }
    return this;
  }

  public function content( required string path ) {
    return structKeyExists(variables.result, arguments.path) ? variables.result[arguments.path] : javaCast( "null", "" );
  }
}