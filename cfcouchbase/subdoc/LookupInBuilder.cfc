/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>This is the main class used to connect and interact with Couchbase</p>
* @author Luis Majano, Brad Wood, Aaron Benton
*/
component serializable="false" accessors="true"{
  /**
  * The document to perform a SubDoc Lookup Operation on
  */
  property name="id" type="string";
  /**
  * A reference to the connected Couchbase Client
  */
  property name="couchbaseClient" type="CouchbaseClient";
  /**
  * A reference to the LookupInBuilder (com.couchbase.client.java.subdoc.LookupInBuilder)
  * http://docs.couchbase.com/sdk-api/couchbase-java-client-2.3.1/com/couchbase/client/java/subdoc/LookupInBuilder.html
  */
  property name="builder";
  /**
  * A reference to the DocumentFragment (com.couchbase.client.java.subdoc.DocumentFragment<OPERATION>)
  * http://docs.couchbase.com/sdk-api/couchbase-java-client-2.3.1/com/couchbase/client/java/subdoc/DocumentFragment.html
  */
  property name="result";

  // Default params, just in case using cf9
  variables['id'] = "";
  variables['couchbaseClient'] = "";
  variables['builder'] = "";
  variables['result'] = "";

  /**
  * Constructor
  * You can pass any name-value pair as arguments to the constructor that matches the properties in this configuration object to be set.
  *
  * @id.hint The id of the document to perform the lookupIn operation on
  * @couchbaseClient.hint A reference to the connected couchbaseClient
  *
  * @return
  */
  public function init( required string id, required couchbaseClient) {

    // Check incoming arguments
    for(var thisArg in arguments){
      if(structKeyExists(arguments, thisArg)){
        variables[thisArg] = arguments[thisArg];
      }
    }

    // set a reference to the builder, as most methods will just call the java class
    variables['builder'] = variables.couchbaseClient.getCouchbaseBucket().lookupIn( variables.id );
    return this;
  }

  /**
  * Calls the builders get method and returns "this" so that multiple calls can be chained
  *
  * @path.hint A dot notation path within the document from the documents root
  *
  * @return LookupInBuilder
  */
  public function get( required paths ) {
    if( isSimpleValue(arguments.paths) ) {
      variables.builder.get( javaCast( "string[]", [ arguments.paths ] ) );
    }
    else if ( isArray(arguments.paths) ) {
      variables.builder.get( javaCast( "string[]", arguments.paths.toArray() ) );
    } else {
      throw(
        message="Invalid path",
        detail="Valid values are a string or array",
        type="CouchbaseClient.LookupInBuilder.InvalidPath"
      );
    }
    return this;
  }

  /**
  * Calls the builders exists method and returns "this" so that multiple calls can be chained
  *
  * @path.hint A dot notation path within the document from the documents root
  *
  * @return LookupInBuilder
  */
  public function exists( required paths ) {
    if( isSimpleValue(arguments.paths) ) {
      variables.builder.exists( javaCast( "string[]", [ arguments.paths ] ) );
    }
    else if ( isArray(arguments.paths) ) {
      variables.builder.exists( javaCast( "string[]", arguments.paths.toArray() ) );
    } else {
      throw(
        message="Invalid path",
        detail="Valid values are a string or array",
        type="CouchbaseClient.LookupInBuilder.InvalidPath"
      );
    }
    return this;
  }

  /**
  * Calls the builders execute method and returns "this" so that multiple calls can be chained.  If the execute
  * method fails with a DocumentDoesNotExistException null is returned instead, allowing for similar behavior to
  * other get methods in the sdk
  *
  * @path.hint A dot notation path within the document from the documents root
  *
  * @return LookupInBuilder or null
  */
  public function execute() {
    try {
      // execute
      variables['result'] = new DocumentFragment(variables.builder.execute(), variables.couchbaseClient);
    } catch( any e ) {
      if (e.type == "com.couchbase.client.java.error.DocumentDoesNotExistException" ) { // trap not found exceptions
        variables['result'] = javaCast( "null", "" );
      } else {
        rethrow;
      }
    }
    return !isNull(variables.result) ? variables.result : javaCast( "null", "" );
  }

}
