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
  */
  property name="LookupInSpecs";
  

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

  
    variables.LookupInSpecs=[];
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
    for( var key in arguments ) {
      var path = arguments[key];
      if ( isArray( path ) ) {
        for( var thispath in path ) {
          addSpec( thispath, couchbaseClient.LookupInSpec.get( thispath ), 'get' );
        }
      } else {
        addSpec( path, couchbaseClient.LookupInSpec.get( path ), 'get' );
      }      
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
    for( var key in arguments ) {
      var path = arguments[key];
      if ( isArray( path ) ) {
        for( var thispath in path ) {
          addSpec( thispath, couchbaseClient.LookupInSpec.exists( thispath ), 'exists' );
        }
      } else {
        addSpec( path, couchbaseClient.LookupInSpec.exists( path ), 'exists' );
      }      
    }
    return this;
  }

  /**
  * Calls the builders count method and returns "this" so that multiple calls can be chained
  *
  * @path.hint A dot notation path within the document from the documents root
  *
  * @return LookupInBuilder
  */
  public function count( required paths ) {
    for( var key in arguments ) {
      var path = arguments[key];
      if ( isArray( path ) ) {
        for( var thispath in path ) {
          addSpec( thispath, couchbaseClient.LookupInSpec.count( thispath ), 'count' );
        }
      } else {
        addSpec( path, couchbaseClient.LookupInSpec.count( path ), 'count' );
      }      
    }
    return this;
  }


  private function addSpec( path, spec, type ) {
    LookupInSpecs.append( {
      path : path,
      spec : spec,
      type : type
    } );    
  }

  /**
  * Calls the builders execute method and returns "this" so that multiple calls can be chained.  If the execute
  * method fails with a DocumentDoesNotExistException null is returned instead, allowing for similar behavior to
  * other get methods in the sdk
  *
  * @path.hint A dot notation path within the document from the documents root
  *
  * @return LookupInBuilder or null if document not found
  */
  public function execute() {
    if( !LookupInSpecs.len() ) {
      throw( 'No lookup specs specified.  Please call get(), exists(), or count() on this object first with a path or array of paths.' )
    }
    try {
      var result = couchbaseClient.getCouchbaseBucket().defaultCollection().lookupIn(
          couchbaseClient.getUtil().normalizeID( getID() ),
          LookupInSpecs.reduce( function(acc,s) {
            return acc.append( s.spec );
          }, [] )
      );
    } catch( any e ) {
      if (e.type == "com.couchbase.client.core.error.DocumentNotFoundException" ) { // trap not found exceptions
        return;
      } else {
        rethrow;
      }
    }
    var i=0;
    var cfResult = {};
    for( var spec in LookupInSpecs ) {
      var exists = result.exists( i );
      if( spec.type == 'exists' ) {
        cfResult[ spec.path ] = exists;
      } else if( ( spec.type == 'count' || spec.type == 'get' ) && exists ) {
          cfResult[ spec.path ] = couchbaseClient.deserializeData( '', toString( result.contentAs( i, javaCast( 'byte[]', [] ).getClass() ), 'utf-8' ) );
      } else {
        cfResult[ spec.path ] = javaCast( 'null', '' );
      }
      i++
    }
    return cfResult;
  }

}
