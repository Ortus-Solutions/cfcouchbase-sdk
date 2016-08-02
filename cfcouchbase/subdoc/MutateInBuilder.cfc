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
  * A reference to the MutateInBuilder (com.couchbase.client.java.subdoc.MutateInBuilder)
  * http://docs.couchbase.com/sdk-api/couchbase-java-client-2.2.8/com/couchbase/client/java/subdoc/MutateInBuilder.html
  */
  property name="builder";
  /**
  * A reference to the DocumentFragment (com.couchbase.client.java.subdoc.DocumentFragment<OPERATION>)
  * http://docs.couchbase.com/sdk-api/couchbase-java-client-2.2.8/com/couchbase/client/java/subdoc/DocumentFragment.html
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
    setBuilder( variables.couchbaseClient.getCouchbaseBucket().mutateIn( variables.id ) );
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
    variables.builder
      .arrayAddUnique(
        javaCast( "string", arguments.path ),
        arguments.value,
        javaCast( "boolean", arguments.createParents )
      );
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
    variables.builder
      .arrayAppend(
        javaCast( "string", arguments.path ),
        arguments.value,
        javaCast( "boolean", arguments.createParents )
      );
    return this;
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
    variables.builder
      .arrayAppendAll(
        javaCast( "string", arguments.path ),
        arguments.values,
        javaCast( "boolean", arguments.createParents )
      );
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
    variables.builder
      .arrayInsert(
        javaCast( "string", arguments.path ),
        arguments.value
      );
    return this;
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
  public function arrayInsertAll( required string path, required any values ) {
    variables.builder
      .arrayInsertAll(
        javaCast( "string", arguments.path ),
        arguments.values
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
    variables.builder
      .arrayPrepend(
        javaCast( "string", arguments.path ),
        arguments.value,
        javaCast( "boolean", arguments.createParents )
      );
    return this;
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
    variables.builder
      .arrayPrependAll(
        javaCast( "string", arguments.path ),
        arguments.values,
        javaCast( "boolean", arguments.createParents )
      );
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
    variables.builder
      .counter(
        javaCast( "string", arguments.path ),
        javaCast( "long", arguments.delta ),
        javaCast( "boolean", arguments.createParents )
      );
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
    variables.builder
      .insert(
        javaCast( "string", arguments.path ),
        arguments.value,
        javaCast( "boolean", arguments.createParents )
      );
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
    variables.builder.remove( javaCast( "string", arguments.path ) );
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
    variables.builder
      .replace(
        javaCast( "string", arguments.path ),
        arguments.value
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
    variables.builder
      .upsert(
        javaCast( "string", arguments.path ),
        arguments.value,
        javaCast( "boolean", arguments.createParents )
      );
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
    variables.builder.withCas( javaCast( "long", arguments.cas ) );
    return this;
  }

  /**
  * Set both a persistence and replication durability constraints for the whole mutation.
  *
  * @persistTo.hint The persistence durability constraint to observe
  * @replicateTo.hint The replication durability constraint to observe
  *
  * @return MutateInBuilder
  */
  public function withDurability( string persistTo, string replicateTo ) {
    // default persist and replicate
    variables.couchbaseClient.defaultPersistReplicate( arguments );
    variables.builder.withDurability( arguments.persistTo, arguments.replicateTo );
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
    variables.builder.withExpiry( javaCast( "int", arguments.expiry ) );
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
    if ( structKeyExists( arguments, "timeout" ) ) {
      variables['result'] = variables.builder.execute(
        javaCast( "long", arguments.timeout ),
        createObject( "java", "java.util.concurrent.TimeUnit" ).MILLISECONDS
      );
    } else {
      variables['result'] = variables.builder.execute();
    }
    return new DocumentFragment( variables.result, variables.couchbaseClient );
  }

}
