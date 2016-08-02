/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>This is the main class used to connect and interact with Couchbase</p>
* @author Luis Majano, Brad Wood, Aaron Benton
*/
component serializable="false" accessors="true"{

  /**
  * A reference to the DocumentFragment (com.couchbase.client.java.subdoc.DocumentFragment<OPERATION>)
  * http://docs.couchbase.com/sdk-api/couchbase-java-client-2.2.8/com/couchbase/client/java/subdoc/DocumentFragment.html
  */
  property name="document";
  /**
  * A reference to the connected Couchbase Client
  */
  property name="couchbaseClient" type="CouchbaseClient";

  // Default params, just in case using cf9
  variables['document'] = "";
  variables['couchbaseClient'] = "";

  /**
  * Constructor
  * You can pass any name-value pair as arguments to the constructor that matches the properties in this configuration object to be set.
  *
  * @id.hint The id of the document to perform the lookupIn operation on
  * @couchbaseClient.hint A reference to the connected couchbaseClient
  *
  * @return
  */
  public function init( required document, required couchbaseClient) {

    // Check incoming arguments
    for(var thisArg in arguments){
      if(structKeyExists(arguments, thisArg)){
        variables[thisArg] = arguments[thisArg];
      }
    }
    return this;
  }

  /**
  * The CAS (Create-and-Set) is set by the SDK when mutating, reflecting the new CAS from the enclosing
  * JSON document.
  *
  * @return The CAS value
  */
  public numeric function cas() {
    return variables.document.cas();
  }

  /**
  * Calls the results content method, certain values are correctly returned as their corresponding
  * CF values.  JsonObject and JsonArray can be returned and are transformed by deserializeData()
  *
  * @path.hint A dot notation path within the document from the documents root
  *
  * @return value
  */
  public any function content( required string path, boolean raw=false ) {
    var data = "";
    if ( arguments.raw ) {
      data = variables.document.content( javaCast( "string", arguments.path ) );
    } else {
      data = variables.couchbaseClient.deserializeData(
        variables.id,
        variables.document.content( javaCast( "string", arguments.path ) )
      );
    }
    return data;
  }

  /**
  * Checks whether the given path or index is part of this result set and the operation was
  * executed successfully.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @index.hint A zero based index to check based on the mutation steps
  *
  * @return exists
  */
  public boolean function exists( required string path, numeric index ) {
    var path_exists = false;
    if ( structKeyExists( arguments, "index" ) ) {
      path_exists = variables.document.exists( javaCast( "int", arguments.index ) );
    } else {
      path_exists = variables.document.exists( javaCast( "string", arguments.path ) );
    }
    return path_exists;
  }

  /**
  * Get the id of the enclosing JSON document in which this fragment belongs.
  *
  * @return document id
  */
  public boolean function id() {
    return variables.document.id();
  }

  /**
  * Gets the number of lookup or mutation specifications that were performed, which is also
  * the number of results.
  *
  * @return results
  */
  public numeric function size() {
    return variables.document.size();
  }

  /**
  * Get the operation status code corresponding to the first operation that targeted the given
  * path. This can be used in place of content(String) in order to avoid an CouchbaseException
  * being thrown.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @index.hint A zero based index to check based on the mutation steps
  *
  * @return com.couchbase.client.core.message.ResponseStatus
  */
  public any function status( string path, numeric index ) {
    var path_status = "";
    if ( structKeyExists( arguments, "index" ) ) {
      path_status = variables.document.status( javaCast( "int", arguments.index ) );
    } else {
      path_status = variables.document.status( javaCast( "string", arguments.path ) );
    }
    return path_status;
  }
}
