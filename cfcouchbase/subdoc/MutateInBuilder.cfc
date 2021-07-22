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
  property name="MutateInSpecs";
  property name="mutateInOptions";


  // Default params, just in case using cf9
  variables['id'] = "";
  variables['couchbaseClient'] = "";
  variables['builder'] = "";

  /**
  * Constructor
  * You can pass any name-value pair as arguments to the constructor that matches the properties in this configuration object to be set.
  *
  * @id.hint The id of the document to perform the lookupIn operation on
  * @couchbaseClient.hint A reference to the connected couchbaseClient
  *
  * @return
  */
  public function init( required string id, required couchbaseClient, required mutateInOptions ) {

    // Check incoming arguments
    for(var thisArg in arguments){
      if(structKeyExists(arguments, thisArg)){
        variables[thisArg] = arguments[thisArg];
      }
    }

    variables.MutateInSpecs=[];
    return this;
  }

  /**
  * Insert a value in an existing array only if the value isn’t already contained in the array
  * (by way of string comparison).
  *
  * @path.hint A dot notation path within the document from the documents root
  * @value.hint The new value to be applied
  * @createParents.hint Whether or not to create missing intermediary / parent nodes
  *
  * @return MutateInBuilder
  */
  public function arrayAddUnique( required string path, required any value, boolean createParents=true ) {
    mutateInSpecs.append( 
      couchbaseClient.MutateInSpec.arrayAddUnique(
        javaCast( "string", arguments.path ),
        arguments.value
      )
    );
    if( arguments.createParents ) {
      mutateInSpecs.last().createPath();
    }
    return this;
  }

  /**
  * Append to an existing array, pushing the value to the back/last position in the array.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @value.hint The new value to be applied
  * @createParents.hint Whether or not to create missing intermediary / parent nodes
  *
  * @return MutateInBuilder
  */
  public function arrayAppend( required string path, required any value, boolean createParents=true ) {
    return arrayAppendAll( path, [ value ], createParents );
  }

  /**
  * Append multiple values at once in an existing array, pushing all values in the collection’s
  * iteration order to the back/end of the array.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @values.hint The collection of values to individually append to the end of the array
  * @createParents.hint Whether or not to create missing intermediary / parent nodes
  *
  * @return MutateInBuilder
  */
  public function arrayAppendAll( required string path, required any values, boolean createParents=true ) {
    mutateInSpecs.append( 
      couchbaseClient.MutateInSpec.arrayAppend(
        javaCast( "string", arguments.path ),
        arguments.values
      )
    );
    if( arguments.createParents ) {
      mutateInSpecs.last().createPath();
    }
    return this;
  }

  /**
  * Insert into an existing array at a specific position (denoted in the path, eg.)
  *
  * @path.hint A dot notation path within the document from the documents root
  * @value.hint The new value to be applied
  *
  * @return MutateInBuilder
  */
  public function arrayInsert( required string path, required any value ) {
     return arrayInsertAll( path, [ value ] );
  }

  /**
  * Insert multiple values at once in an existing array at a specified position (denoted in
  * the path, eg.)
  *
  * @path.hint A dot notation path within the document from the documents root
  * @value.hint The collection of values to individually append to the end of the array
  *
  * @return MutateInBuilder
  */
  public function arrayInsertAll( required string path, required any values) {
    mutateInSpecs.append( 
      couchbaseClient.MutateInSpec.arrayInsert(
        javaCast( "string", arguments.path ),
        arguments.values
      )
    );
    return this;
  }

  /**
  * Prepend to an existing array, pushing the value to the front/first position in the array.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @value.hint The new value to be applied
  * @createParents.hint Whether or not to create missing intermediary / parent nodes
  *
  * @return MutateInBuilder
  */
  public function arrayPrepend( required string path, required any value, boolean createParents=true ) {
    return arrayPrependAll( path, [ value ], createParents );
  }

  /**
  * Prepend multiple values at once in an existing array, pushing all values in the
  * collection’s iteration order to the front/start of the array.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @value.hint The collection of values to individually preprend to the front of the array
  * @createParents.hint Whether or not to create missing intermediary / parent nodes
  *
  * @return MutateInBuilder
  */
  public function arrayPrependAll( required string path, required any values, boolean createParents=true ) {
    mutateInSpecs.append( 
      couchbaseClient.MutateInSpec.arrayPrepend(
        javaCast( "string", arguments.path ),
        arguments.values
      )
    );
    if( arguments.createParents ) {
      mutateInSpecs.last().createPath();
    }
    return this;
  }

  /**
  * Increment/decrement a numerical fragment in a JSON document.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @delta.hint The value to increment or decrement the counter by
  * @createParents.hint Whether or not to create missing intermediary / parent nodes
  *
  * @return MutateInBuilder
  */
  public function counter( required string path, required numeric delta, boolean createParents=true ) {
    if( delta > 0 ) {
      return increment( path, abs( delta ), createParents );
    } else {
      return decrement( path, abs( delta ), createParents );
    }
  }

  /**
  * Increment a numerical fragment in a JSON document.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @delta.hint The value to increment or decrement the counter by
  * @createParents.hint Whether or not to create missing intermediary / parent nodes
  *
  * @return MutateInBuilder
  */
  public function increment( required string path, required numeric delta, boolean createParents=true ) {
    mutateInSpecs.append( 
      couchbaseClient.MutateInSpec.increment(
        javaCast( "string", arguments.path ),
        javaCast( "long", arguments.delta )
      )
    );
    if( arguments.createParents ) {
      mutateInSpecs.last().createPath();
    }
    return this;
  }

  /**
  * decrement a numerical fragment in a JSON document.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @delta.hint The value to increment or decrement the counter by
  * @createParents.hint Whether or not to create missing intermediary / parent nodes
  *
  * @return MutateInBuilder
  */
  public function decrement( required string path, required numeric delta, boolean createParents=true ) {
    mutateInSpecs.append( 
      couchbaseClient.MutateInSpec.decrement(
        javaCast( "string", arguments.path ),
        javaCast( "long", arguments.delta )
      )
    );
    if( arguments.createParents ) {
      mutateInSpecs.last().createPath();
    }
    return this;
  }

  /**
  * Insert a fragment provided the last element of the path doesn’t exists.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @value.hint The new value to be applied
  * @createParents.hint Whether or not to create missing intermediary / parent nodes
  *
  * @return MutateInBuilder
  */
  public function insert( required string path, required any value, boolean createParents=true ) {
    mutateInSpecs.append( 
      couchbaseClient.MutateInSpec.insert(
        javaCast( "string", arguments.path ),
        arguments.value
      )
    );
    if( arguments.createParents ) {
      mutateInSpecs.last().createPath();
    }
    return this;
  }

  /**
  * Remove an entry in a JSON document (scalar, array element, dictionary entry,
  * whole array or dictionary, depending on the path).
  *
  * @path.hint A dot notation path within the document from the documents root
  *
  * @return MutateInBuilder
  */
  public function remove( required string path ) {
    mutateInSpecs.append( 
      couchbaseClient.MutateInSpec.remove(
        javaCast( "string", arguments.path )
      )
    );
    return this;
  }

  /**
  * Replace an existing value by the given fragment.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @value.hint The new value to be applied
  *
  * @return MutateInBuilder
  */
  public function replace( required string path, required any value ) {
    mutateInSpecs.append( 
      couchbaseClient.MutateInSpec.replace(
        javaCast( "string", arguments.path ),
        arguments.value
      )
    );
    return this;
  }

  /**
  * Insert a fragment, replacing the old value if the path exists.
  *
  * @path.hint A dot notation path within the document from the documents root
  * @value.hint The new value to be applied
  * @createParents.hint Whether or not to create missing intermediary / parent nodes
  *
  * @return MutateInBuilder
  */
  public function upsert( required string path, required any value, boolean createParents=true ) {
    mutateInSpecs.append( 
      couchbaseClient.MutateInSpec.upsert(
        javaCast( "string", arguments.path ),
        arguments.value
      )
    );
    if( arguments.createParents ) {
      mutateInSpecs.last().createPath();
    }
    return this;
  }

  /**
  * Apply the whole mutation using optimistic locking, checking against the provided CAS value.
  *
  * @cas.hint The CAS value to compare the enclosing document to
  *
  * @return MutateInBuilder
  */
  public function withCas( required numeric cas ) {
    mutateInOptions.cas( javaCast( "long", arguments.cas ) );
    return this;
  }

  /**
  * Set both a persistence and replication durability constraints for the whole mutation.
  *
  * @persistTo.hint The persistence durability constraint to observe. Valid values: NONE, MASTER, ONE, TWO, THREE, FOUR
  * @replicateTo.hint The replication durability constraint to observe. Valid values: NONE, ONE, TWO, THREE
  * 
  * @return MutateInBuilder
  */
  public function withDurability( string persistTo, string replicateTo ) {
    // default persist and replicate
    variables.couchbaseClient.defaultPersistReplicate( arguments, mutateInOptions );
    return this;
  }

  /**
  * Change the expiry of the enclosing document as part of the mutation.
  *
  * @expiry.hint The new expiry to apply (or 0 to avoid changing the expiry)
  *
  * @return MutateInBuilder
  */
  public function withExpiry( required numeric expiry ) {
    variables.couchbaseClient.defaultTimeout( { timeout : expiry }, mutateInOptions );
    return this;
  }

  /**
  * Changes the storing semantics of the outer/enclosing document.
  *
  * @storeSemantic.hint One of the values INSERT, REPLACE, or UPSERT
  *
  * @return MutateInBuilder
  */
  public function storeSemantics( required string storeSemantic ) {
    mutateInOptions.storeSemantics( variables.couchbaseClient.newJava( 'com.couchbase.client.java.kv.StoreSemantics' ).valueOf( uCase( arguments.storeSemantic ) ) );
    return this;
  }

  /**
  * Perform several mutation operations inside a single existing JSON document, with a specific timeout. The
  * list of mutations and paths to mutate in the JSON is added through builder methods like
  * arrayInsert(String, Object).  If the execute method fails with a DocumentDoesNotExistException null is
  * returned instead, allowing for similar behavior to other get methods in the sdk
  *
  * @timeout.hint The timeout in milliseconds
  *
  * @return MutateInBuilder or null
  */
  public function execute( numeric timeout ) {

    if( !mutateInSpecs.len() ) {
      throw( 'No mutate specs specified.  Please call methods on this object first to describe the mutation(s) to perform.' )
    }
    if( !isNull( arguments.timeout ) ) {
      mutateInOptions.timeout( variables.couchbaseClient.newJava( 'java.time.Duration' ).ofMillis( arguments.timeout ) )
    }
    var MutateInResult = couchbaseClient.getCouchbaseBucket().defaultCollection().mutateIn(
        couchbaseClient.getUtil().normalizeID( getID() ),
        mutateInSpecs,
        mutateInOptions
    );
    return MutateInResult;

  }

}
