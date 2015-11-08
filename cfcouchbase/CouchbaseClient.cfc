/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>This is the main class used to connect and interact with Couchbase</p>
* @author Luis Majano, Brad Wood, Aaron Benton
*/
component serializable="false" accessors="true" {
  /**
  * The version of this library
  */
  property name="version";
  /**
  * The version of the Couchbase SDK
  */
  property name="SDKVersion";
  /**
  * The unique ID of this SDK
  */
  property name="libID";
  /**
  * The UUID Helper
  */
  property name="uuidHelper";
  /**
  * The java Couchbase Cluster object
  */
  property name="couchbaseCluster";
  /**
  * The java Couchbase Bucket object
  */
  property name="couchbaseBucket";
  /**
  *The couchbase configuration object
  */
  property name="couchbaseConfig";
  /**
  * The SDK utility class
  */
  property name="util";
  /**
  * The data marshaller to use for serializations and deserializations
  */
  property name="dataMarshaller" type="cfcouchbase.data.IDataMarshaller";

  /**
  * Constructor
  * This creates a connection to a Couchbase server using the passed in config argument, which can be a struct literal of options, a path to a config object
  * or an instance of a cfcouchbase.config.CouchbaseConfig object.  For all the possible config settings, look at the CouchbaseConfig object.
  *
  * @config.hint The configuration structure, config object or path to a config object.
  *
  * @return A reference to "this" CFC
  */
  CouchbaseClient function init( any config= {} ) {

    /****************** Setup SDK dependencies & properties ******************/

    // The version of the client and sdk
    variables['version'] = "1.1.0.@build.number@";
    variables['SDKVersion'] = "2.2.0";
    // The unique version of this client
    variables['libID'] = createObject( "java", "java.lang.System" ).identityHashCode( this );
    // lib path
    variables['libPath'] = getDirectoryFromPath( getMetadata( this ).path ) & "lib";
    // setup class loader ID
    variables['javaLoaderID'] = "cfcouchbase-" & variables.version & "-classloader";
    // our UUID creation helper
    variables['UUIDHelper'] = createobject( "java", "java.util.UUID" );
    // Java Time Units
    variables['timeUnit'] = createObject( "java", "java.util.concurrent.TimeUnit" );
    // validate configuration
    variables['couchbaseConfig'] = validateConfig( arguments.config );
    // SDK Utility class
    variables['util'] = new util.Utility( variables.couchbaseConfig );

    // Load up javaLoader with Couchbase SDK
    if( variables.couchbaseConfig.getUseClassloader() ) {
      loadSDK();
    }

    // LOAD ENUMS
		this['persistTo'] = newJava( "com.couchbase.client.java.PersistTo" );
		this['replicateTo'] = newJava( "com.couchbase.client.java.ReplicateTo" );
    this['replicaMode'] = newJava( "com.couchbase.client.java.ReplicaMode" );

    // Establish a connection to the Couchbase bucket
    variables['couchbaseBucket'] = buildCouchbaseClient( variables.couchbaseConfig );
    // Build the data marshaler
    variables['dataMarshaller'] = buildDataMarshaller( variables.couchbaseConfig ).setCouchbaseClient( this );
    // Query Helper Utility
    variables['queryHelper'] = new util.QueryHelper( this );
    return this;
  }

  /************************* COUCHBASE SDK METHODS ***********************************/

  /**
  * Upsert ( Update/Insert ) a value with durability options. It is synchronous by default so it waits for the set to complete. To force the document to be replicated
  * to additional nodes, pass the replicateTo argument.  A value of ReplicateTo.TWO ensures the document is copied to at least two replica nodes, etc.  ( This assumes you have replicas enabled )
  * To force the document to be perisited to disk, passing in PersistTo.ONE ensures it is stored on disk in a single node.  PersistTo.TWO ensures 2 nodes, etc.
  * A PersistTo.TWO durability setting implies a replication to at least one node.
  *
  * <pre class='brush: cf'>
  * person = { name: "Brad", age: 33, hair: "red" };
  * client.upsert( 'brad', person );
  * </pre>
  *
  * @id.hint The unique id of the document to store
  * @value.hint The value to store
  * @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ NONE, ONE, TWO, THREE ]
  *
  * @return A structure containing the id, cas, expiry and hashCode document metadata values
  */
  public any function upsert(
    required string id,
    required any value,
    numeric timeout,
    string persistTo,
    string replicateTo
  ) {
    // default timeout
    defaultTimeout( arguments );
    // default persist and replicate
    defaultPersistReplicate( arguments );
    // create a new document to be saved
    var document = newPopulatedDocument( argumentCollection=arguments );
    var result = variables.couchbaseBucket.upsert(
      document,
      arguments.persistTo,
      arguments.replicateTo
    );
    return {
      'id' = result.id(),
      'cas' = result.cas(),
      'expiry' = result.expiry(),
      'hashCode' = result.hashCode()
    };
  }

  /**
  * Creates a new populated document java object with the id, expiry, content, cas.  To ensure that
  * documents are correctly stored we need to generate the correct document type java object. This
  * is even more important when string documents are going to be used with legacy operations such
  * as append / prepend.
  *
  * @id.hint The unique id of the document to store
  * @value.hint The value to store
  * @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
  * @cas.hint The cas value of the document
  * @legacy.hint Whether or not to create a legacy document type
  * @dataType.hint An explicitly known data type otherwise it is determined
  *
  * @return The Java Object representation of the data
  */
  public any function newPopulatedDocument(
    required string id,
    required any value,
    numeric timeout=0,
    numeric cas=0
    boolean legacy=false,
    string dataType=""
  ) {
    // make sure that legacy exists, even though we set a default this method is called through
    // argumentCollection and thus legacy won't always exist
    if( !structKeyExists( arguments, "legacy" ) ) {
      arguments['legacy'] = false;
    }
    var document = "";
    // if the data type was pass just use it, otherwise infer it
    arguments['dataType'] = len( arguments.dataType ) ? arguments.dataType : variables.util.getDataType( arguments.value );
    // are we dealing with legacy documents?
    if( arguments.legacy ) {
      switch( arguments.dataType ) {
        case "binary":
          document = newJava( "com.couchbase.client.java.document.BinaryDocument" ).create(
            // normalize the id before setting it
            javaCast( "string", variables.util.normalizeID( arguments.id ) ),
            // set the expiry / timeout in minutes
            javaCast( "int", arguments.timeout ),
            // create a new binary from the value, should be a com.couchbase.client.deps.io.netty.buffer.ByteBuf object
            arguments.value,
            // set the cas value
            javaCast( "long", arguments.cas )
          );
        break;
        case "string":
          document = newJava( "com.couchbase.client.java.document.StringDocument" ).create(
            // normalize the id before setting it
            javaCast( "string", variables.util.normalizeID( arguments.id ) ),
            // set the expiry / timeout in minutes
            javaCast( "int", arguments.timeout ),
            // create a new string from the value
            javaCast( "string", arguments.value ),
            // set the cas value
            javaCast( "long", arguments.cas )
          );
        break;
        default:
          document = newJava( "com.couchbase.client.java.document.LegacyDocument" ).create(
            // normalize the id before setting it
            javaCast( "string", variables.util.normalizeID( arguments.id ) ),
            // set the expiry / timeout in minutes
            javaCast( "int", arguments.timeout ),
            // create a new string from the value
            serializeData( arguments.value ),
            // set the cas value
            javaCast( "long", arguments.cas )
          );
      }
    }
    else {
      switch( arguments.dataType ) {
        case "struct":
          // create a new JsonDocument from a JsonObject to be saved
          document = newJava( "com.couchbase.client.java.document.JsonDocument" ).create(
            // normalize the id before setting it
            javaCast( "string", variables.util.normalizeID( arguments.id ) ),
            // set the expiry / timeout in minutes
            javaCast( "int", arguments.timeout ),
            // create a new JsonObject from the value
            newJava( "com.couchbase.client.java.document.json.JsonObject" ).fromJson( serializeData( arguments.value ) ),
            // set the cas value
            javaCast( "long", arguments.cas )
          );
        break;
        case "array":
          // create a new JsonArrayDocument from a JsonArray to be saved
          document = newJava( "com.couchbase.client.java.document.JsonArrayDocument" ).create(
            // normalize the id before setting it
            javaCast( "string", variables.util.normalizeID( arguments.id ) ),
            // set the expiry / timeout in minutes
            javaCast( "int", arguments.timeout ),
            // create a new JsonObject from the value
            newJava( "com.couchbase.client.java.document.json.JsonArray" ).from( arguments.value ),
            // set the cas value
            javaCast( "long", arguments.cas )
          );
        break;
        case "double":
          // create a new JsonDoubleDocument from a value to be saved
          document = newJava( "com.couchbase.client.java.document.JsonDoubleDocument" ).create(
            // normalize the id before setting it
            javaCast( "string", variables.util.normalizeID( arguments.id ) ),
            // set the expiry / timeout in minutes
            javaCast( "int", arguments.timeout ),
            // create a new double from the value
            javaCast( "double", arguments.value ),
            // set the cas value
            javaCast( "long", arguments.cas )
          );
        break;
        case "long":
          // create a new JsonLongDocument from a value to be saved
          document = newJava( "com.couchbase.client.java.document.JsonLongDocument" ).create(
            // normalize the id before setting it
            javaCast( "string", variables.util.normalizeID( arguments.id ) ),
            // set the expiry / timeout in minutes
            javaCast( "int", arguments.timeout ),
            // create a new long from the value
            javaCast( "long", arguments.value ),
            // set the cas value
            javaCast( "long", arguments.cas )
          );
        break;
        case "binary":
          // create a new BinaryDocument from a value to be saved
          document = newJava( "com.couchbase.client.java.document.BinaryDocument" ).create(
            // normalize the id before setting it
            javaCast( "string", variables.util.normalizeID( arguments.id ) ),
            // set the expiry / timeout in minutes
            javaCast( "int", arguments.timeout ),
            // create a new binary from the value, should be a com.couchbase.client.deps.io.netty.buffer.ByteBuf object
            arguments.value,
            // set the cas value
            javaCast( "long", arguments.cas )
          );
        break;
        case "boolean":
          // create a new BooleanDocument from a value to be saved
          document = newJava( "com.couchbase.client.java.document.JsonBooleanDocument" ).create(
            // normalize the id before setting it
            javaCast( "string", variables.util.normalizeID( arguments.id ) ),
            // set the expiry / timeout in minutes
            javaCast( "int", arguments.timeout ),
            // create a new boolean from the value
            javaCast( "boolean", arguments.value ),
            // set the cas value
            javaCast( "long", arguments.cas )
        );
        break;
        case "string":
          // create a new JsonStringDocument from a value to be saved
          document = newJava( "com.couchbase.client.java.document.JsonStringDocument" ).create(
            // normalize the id before setting it
            javaCast( "string", variables.util.normalizeID( arguments.id ) ),
            // set the expiry / timeout in minutes
            javaCast( "int", arguments.timeout ),
            // create a new string from the value
            javaCast( "string", arguments.value ),
            // set the cas value
            javaCast( "long", arguments.cas )
          );
        break;
        default: // the data type could be determined, just serialize the data
          // create a new RawJsonDocument from a value to be saved
          document = newJava( "com.couchbase.client.java.document.RawJsonDocument" ).create(
            // normalize the id before setting it
            javaCast( "string", variables.util.normalizeID( arguments.id ) ),
            // set the expiry / timeout in minutes
            javaCast( "int", arguments.timeout ),
            // create a new string from the value
            serializeData( arguments.value ),
            // set the cas value
            javaCast( "long", arguments.cas )
          );
      }
    }
    return document;
  }

  /**
  * Creates a new populated document java object without any values.  This is used to ensure that
  * retrieved documents are correctly represented once retrieved.  Older legacy documents cannot be
  * correctly retrieved otherwise.
  *
  * @value.hint The value to store
  * @legacy.hint Whether or not to create a legacy document
  * @dataType.hint The data type to determine the type of Java Object to create
  *
  * @return The Java Object representation of the data to be retrieved
  */
  public any function newEmptyDocument(
    boolean legacy=false,
    string dataType="unknown",
    any value=""
  ) {
    // make sure that legacy exists, even though we set a default this method is called through
    // argumentCollection and thus legacy won't always exist
    if( !structKeyExists( arguments, "legacy" ) ) {
      arguments['legacy'] = false;
    }
    var document = "";
    // if the data type was pass just use it, otherwise infer it
    arguments['dataType'] = len( arguments.dataType ) ? arguments.dataType : variables.util.getDataType( arguments.value );

    // are we dealing with legacy documents?
    if( arguments.legacy ) {
      switch( arguments.dataType ) {
        case "binary":
          document = newJava( "com.couchbase.client.java.document.BinaryDocument" );
        break;
        case "string":
          document = newJava( "com.couchbase.client.java.document.StringDocument" );
        break;
        default:
          document = newJava( "com.couchbase.client.java.document.LegacyDocument" );
      }
    }
    else {
      switch( arguments.dataType ) {
        case "struct":
          document = newJava( "com.couchbase.client.java.document.JsonDocument" );
        break;
        case "array":
          document = newJava( "com.couchbase.client.java.document.JsonArrayDocument" );
        break;
        case "double":
          document = newJava( "com.couchbase.client.java.document.JsonDoubleDocument" );
        break;
        case "long":
          document = newJava( "com.couchbase.client.java.document.JsonLongDocument" );
        break;
        case "binary":
          document = newJava( "com.couchbase.client.java.document.JsonDocument" );
        break;
        case "boolean":
          document = newJava( "com.couchbase.client.java.document.JsonDocument" );
        break;
        case "string":
          document = newJava( "com.couchbase.client.java.document.JsonDocument" );
        break;
        default:
          document = newJava( "com.couchbase.client.java.document.RawJsonDocument" );
      }
    }
    return document;
  }

  /**
  * Set a value with durability options. The set() method is no longer supported by the 2.x SDK and this actually calls
  * upsert().  However the difference is the type of document that is created, upsert() will use the new Json*Document
  * objects and this uses the legacy StringDocument, BinaryDocument or LegacyDocument. This is important especially for
  * StringDocuments as string documents are the only documents that can truly be appended / prepended to. It is
  * synchronous by default so it waits for the set to complete. To force the document to be replicated to additional
  * nodes, pass the replicateTo argument.  A value of ReplicateTo.TWO ensures the document is copied to at least two
  * replica nodes, etc.  ( This assumes you have replicas enabled ) To force the document to be perisited to disk,
  * passing in PersistTo.ONE ensures it is stored on disk in a single node.  PersistTo.TWO ensures 2 nodes, etc. A
  * PersistTo.TWO durability setting implies a replication to at least one node.
  *
  * <pre class='brush: cf'>
  * person = { name: "Brad", age: 33, hair: "red" };
  * client.set( 'brad', person );
  * </pre>
  *
  * @id.hint The unique id of the document to store
  * @value.hint The value to store
  * @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  *
  * @return A structure containing the id, cas, expiry and hashCode document metadata values
  */
  public any function set(
    required string id,
    required any value,
    numeric timeout,
    string persistTo,
    string replicateTo
  ) {
    // we are dealing with an old sdk 1.x method, assume that we are wanting to create legacy documents
    arguments['legacy'] = true;
    return this.upsert( argumentCollection=arguments );
  }

  /**
  * Replace the value of an existing document with a CAS value.  CAS is retrieved via getWithCAS().  Since the CAS value changes every time a document is modified
  * you will be able to tell if another process has modified the document between the time you retrieved it and updated it.  This method will only complete
  * successfully if the original document value is unchanged.  This method is not asyncronous and therefore does not return a future since your application code
  * will need to check the return and handle it appropriatley.
  *
  * <pre class='brush: cf'>
  * person = { name: "Brad", age: 33, hair: "red" };
  * result = client.replaceWithCAS( 'brad', person, CAS );
  * </pre>
  *
  * @id.hint The unique id of the document to store
  * @value.hint The value to store
  * @CAS.hint CAS value retrieved via getWithCAS()
  * @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  *
  * @return A struct with a status and detail key.  Status will be true if the document was succesfully updated.  If status is false, that means nothing happened on the server and you need to re-issue a command to store your document.  When status is false, check the detail.  A value of "CAS_CHANGED" indicates that anothe rprocess has updated the document and your version is out-of-date.  You will need to retrieve the document again with getWithCAS() and attempt your setWithCAS again.  If status is false and details is "NOT_FOUND", that means a document with that ID was not found.  You can then issue an add() or a regular set() commend to store the document.
  */
  public any function replaceWithCAS(
    required string id,
    required any value,
    required numeric cas,
    numeric timeout,
    string persistTo,
    string replicateTo
  ) {
    // default timeout
    defaultTimeout( arguments );
    // default persist and replicate
    defaultPersistReplicate( arguments );
    // create a new RawJsonDocument to be saved
    var document = newJava( "com.couchbase.client.java.document.RawJsonDocument" ).create(
      // normalize the id before setting it
      variables.util.normalizeID( arguments.id ),
      // set the expiry / timeout in minutes
      javaCast( "int", arguments.timeout ),
      // serialize the data
      serializeData( arguments.value ),
      // set the cas value
      javaCast( "long", arguments.cas )
    );
    var response = "";
    var result = {
      'status' = true,
      'detail' = "SUCCESS"
    };
    try {
      response = variables.couchbaseBucket.replace(
        document,
        arguments.persistTo,
        arguments.replicateTo
      );
    }
    catch( any e ) {
      switch( e.type ) {
        // the cas value is invalid
        case "com.couchbase.client.java.error.CASMismatchException":
          result['status'] = false;
          result['detail'] = "CAS_CHANGED";
        break;
        // the document was not found
        case "com.couchbase.client.java.error.DocumentDoesNotExistException":
          result['status'] = false;
          result['detail'] = "NOT_FOUND";
        break;
        default:
          rethrow;
      }
    }
    return result;
  }

  /**
  * Replace the value of an existing document with a CAS value, as set() is deprecated this calls replaceWithCas with the legacy document type set to true.
  * The upsert() method does not support cas operations.
  *
  * <pre class='brush: cf'>
  * person = { name: "Brad", age: 33, hair: "red" };
  * result = client.setWithCas( 'brad', person, CAS );
  * </pre>
  *
  * @id.hint The unique id of the document to store
  * @value.hint The value to store
  * @CAS.hint CAS value retrieved via getWithCAS()
  * @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  *
  * @return A struct with a status and detail key.  Status will be true if the document was succesfully updated.  If status is false, that means nothing happened on the server and you need to re-issue a command to store your document.  When status is false, check the detail.  A value of "CAS_CHANGED" indicates that anothe rprocess has updated the document and your version is out-of-date.  You will need to retrieve the document again with getWithCAS() and attempt your setWithCAS again.  If status is false and details is "NOT_FOUND", that means a document with that ID was not found.  You can then issue an add() or a regular set() commend to store the document.
  */
  public any function setWithCAS(
    required string id,
    required any value,
    required string cas,
    numeric timeout,
    string persistTo,
    string replicateTo
  ) {
    // we are dealing with an old sdk 1.x method, assume that we are wanting to create legacy documents
    arguments['legacy'] = true;
    return this.replaceWithCAS( argumentCollection=arguments );
  }

  /**
  * This method is the same as upsert(), except it will return true if the ID being set doesn't already exist.
  * It will return false if the item being set does already exist.
  *
  * <pre class='brush: cf'>
  * person = { name: "Brad", age: 33, hair: "red" };
  * client.insert( 'brad', person );
  * </pre>
  *
  * @id.hint
  * @value.hint
  * @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  *
  * @return A boolean indicating whether or not the insert was successful
  */
  public boolean function insert(
    required string id,
    required any value,
    numeric timeout,
    string persistTo,
    string replicateTo
  ) {
    // default timeout
    defaultTimeout( arguments );
    // default persist and replicate
    defaultPersistReplicate( arguments );
    // we are dealing with a new sdk 2.x+ method set legacy to false
    arguments['legacy'] = false;
    // create a new document to be saved
    var document = newPopulatedDocument( argumentCollection=arguments );
    var success = true;
    try {
      variables.couchbaseBucket.insert(
        document,
        arguments.persistTo,
        arguments.replicateTo
      );
    }
    catch( any e ) {
      // the document already exists and cannot be inserted
      if( e.type == "com.couchbase.client.java.error.DocumentAlreadyExistsException" ) {
        success = false;
      }
      else {
        rethrow;
      }
    }
    return success;
  }

  /**
  * This method is the same as set(), except it return true if the ID being set doesn't already exist.
  * It will return false if the item being set does already exist.
  *
  * <pre class='brush: cf'>
  * person = { name: "Brad", age: 33, hair: "red" };
  * future = client.insert( 'brad', person );
  * </pre>
  *
  * @id.hint
  * @value.hint
  * @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  *
  * @return A boolean indicating whether or not the insert was successful
  */
  public boolean function add(
    required string id,
    required any value,
    numeric timeout,
    string persistTo,
    string replicateTo
  ) {
    // we are dealing with an old sdk 1.x method, assume that we are wanting to create legacy documents
    arguments['legacy'] = true;
    return this.insert( argumentCollection=arguments );
  }

  /**
  * Upsert multiple documents in the cache with a single operation.  Pass in a struct of documents to set where the IDs of the struct are the document IDs.
  * The values in the struct are the values being set.  All documents share the same timout, persistTo, and replicateTo settings.
  *
  * <pre class='brush: cf'>
  * data = {
  * &nbsp;&nbsp;brad = { name: "Brad", age: 33, hair: "red" },
  * &nbsp;&nbsp;luis = { name: "Luis", age: 35, hair: "black" },
  * &nbsp;&nbsp;bill = { name: "Bill", age: 21, hair: "blond" }
  * };
  * future = client.setMulti( data );
  * </pre>
  *
  * @data.hint A struct ( key/value pair ) of documents to set into Couchbase.
  * @timeout.hint The expiration of the documents in minutes.
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  *
  * @return A struct of IDs with each of the future objects from the set operations.  There will be no future object if a timeout occurs.
  */
  public any function upsertMulti(
    required struct data,
    numeric timeout,
    string persistTo,
    string replicateTo
  ) {
    var results = {};
    // default persist and replicate
    defaultPersistReplicate( arguments );
    // default timeouts
    defaultTimeout( arguments );
    // Loop over incoming key/value pairs
    for( var id in arguments.data ) {
      // save the result
      results[id] = this.upsert(
        id=id,
        value=serializeData( arguments.data[id] ),
        timeout=arguments.timeout,
        persistTo=arguments.persistTo,
        replicateTo=arguments.replicateTo
      );
    }
    return results;
  }

  /**
  * Set multiple documents in the cache with a single operation.  Pass in a struct of documents to set where the IDs of the struct are the document IDs.
  * The values in the struct are the values being set.  All documents share the same timout, persistTo, and replicateTo settings.
  *
  * <pre class='brush: cf'>
  * data = {
  * &nbsp;&nbsp;brad = { name: "Brad", age: 33, hair: "red" },
  * &nbsp;&nbsp;luis = { name: "Luis", age: 35, hair: "black" },
  * &nbsp;&nbsp;bill = { name: "Bill", age: 21, hair: "blond" }
  * };
  * future = client.setMulti( data );
  * </pre>
  *
  * @data.hint A struct ( key/value pair ) of documents to set into Couchbase.
  * @timeout.hint The expiration of the documents in minutes.
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  *
  * @return A struct of IDs with each of the future objects from the set operations.  There will be no future object if a timeout occurs.
  */
  public any function setMulti(
    required struct data,
    numeric timeout,
    string persistTo,
    string replicateTo
  ) {
    // we are dealing with an old sdk 1.x method, assume that we are wanting to create legacy documents
    arguments['legacy'] = true;
    return this.upsertMulti( argumentCollection=arguments );
  }

  /**
  * This method will set a value only if that ID already exists in Couchbase.  If the document ID doesn't exist, it will do nothing.
  *
  * <pre class='brush: cf'>
  * person = { name: "Brad", age: 33, hair: "red" };
  * client.replace( 'brad', person );
  * </pre>
  *
  * @id.hint The ID of the document to replace.
  * @value.hint The value of the document to replace
  * @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  *
  * @return A boolean indicating whether or not the replace was successful
  */
  public boolean function replace(
    required string id,
    required any value,
    numeric timeout,
    string persistTo,
    string replicateTo,
    numeric cas=0
  ) {
    // default timeout
    defaultTimeout( arguments );
    // default persist and replicate
    defaultPersistReplicate( arguments );
    // create a new document to be saved
    var document = newPopulatedDocument( argumentCollection=arguments );
    var success = true;
    try {
      variables.couchbaseBucket.replace(
        document,
        arguments.persistTo,
        arguments.replicateTo
      );
    }
    catch( any e ) {
      // the document does not exist and can't be replaced
      if( e.type == "com.couchbase.client.java.error.DocumentDoesNotExistException" ) {
        success = false;
      }
      else {
        rethrow;
      }
    }
    return success;
  }

  /**
  * Get an object from couchbase by the ID.  This method will deserialize object automatically and optionally inflate the data into a CFC.
  *
  * <pre class='brush: cf'>
  * person = client.get( 'brad' );
  * </pre>
  *
  * @id.hint The ID of the document to retrieve.
  * @deserialize.hint Deserialize the JSON automatically for you and return the representation
  * @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
  * @inflateTo.hint The object that will be used to inflate the data with according to our conventions
  *
  * @return The object if found, null otherwise.
  */
  public any function get(
    required string id,
    boolean deserialize=true,
    struct deserializeOptions={},
    any inflateTo="",
    string dataType="json",
    boolean legacy=false
  ) {
    // couchbase expects a target class to inflate the results to, in this case we just want the raw
    // result and we will handle the deserialization on our side
    var document = newEmptyDocument( argumentCollection=arguments ).create(
      variables.util.normalizeID( arguments.id )
    );
    var result = "";
    try {
      result = variables.couchbaseBucket.get( document );
    }
    catch( any e ) {
      // basically an attempt was made to retrieve a legacy document that cannot be inflated
      // to the new Json*Document objects provided by the SDK.  try to get the document as a
      // legacy document
      if( e.type == "com.couchbase.client.java.error.TranscodingException" ) {
        arguments['legacy'] = true;
        // rebuild a new document shell
        document = newEmptyDocument( argumentCollection=arguments ).create(
          variables.util.normalizeID( arguments.id )
        );
        // try to get the results again
        result = variables.couchbaseBucket.get( document );
      }
      else {
        rethrow;
      }
    }
    if( !isNull( result ) ) {
      return deserializeData(
        arguments.id,
        result.content(),
        arguments.inflateTo,
        arguments.deserialize,
        arguments.deserializeOptions
      );
    }
  }

  /**
  * Get an object from couchbase asynchronously.
  *
  * <pre class='brush: cf'>
  * observable = client.asyncGet( 'brad' );
  * </pre>
  *
  * @id.hint The ID of the document to retrieve.
  *
  * @return A Java Observable ( rx.Observable )
  */
  public any function asyncGet( required string id ) {
    throw(
      message="async options not supported",
      detail="The asyncGet method is not currently supported.",
      type="CouchbaseClient.NotSupported"
    );
  }

  /**
  * Get multiple objects from couchbase.
  *
  * <pre class='brush: cf'>
  * results = client.getMulti( ['brad', 'luis', 'bill'] );
  * </pre>
  *
  * @id.hint An array of document IDs to retrieve.
  * @deserialize.hint Deserialize the JSON automatically for you and return the representation
  * @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
  * @inflateTo.hint The object that will be used to inflate the data with according to our conventions
  *
  * @return A struct of values.  Any document IDs not found will not exist in the struct.
  */
  public any function getMulti(
    required array ID,
    boolean deserialize=true,
    struct deserializeOptions={},
    any inflateTo=""
  ) {
    var result = {};
    // normalize the id's
    arguments['id'] = variables.util.normalizeID( arguments.id );
    // In the java 2.0 sdk all synchronous bulk operations were removed, now they are only available
    // through async() to still provide a synchronous version a get is issued for each document
    for( var doc_id in arguments.id ) {
      result[doc_id] = get( doc_id, deserialize, deserializeOptions, inflateTo );
    }
    return result;
  }

  /**
  * Get multiple objects from couchbase asynchronously.
  *
  * <pre class='brush: cf'>
  * buldFuture = client.asyncGetMulti( ['brad', 'luis', 'bill'] );
  * </pre>
  *
  * @id.hint An array of document IDs to retrieve.
  *
  * @return A bulk Java Future. ( net.spy.memcached.internal.BulkFuture )  Any document IDs not found will not exist in the future object.
  */
  public any function asyncGetMulti( required array id ) {
    throw(
      message="async options not supported",
      detail="The asyncGetMulti method is not currently supported.",
      type="CouchbaseClient.NotSupported"
    );
  }

  /**
  * Get an object from couchbase with its CAS value, returns null if not found.  This method is meant to be used in conjunction with replaceWithCAS to be able to
  * update a document while making sure another process hasn't modified it in the meantime.  The CAS value changes every time the document is updated.
  *
  * <pre class='brush: cf'>
  * result = client.getWithCAS( 'brad' );
  * writeOutput( result.cas );
  * writeOutput( result.value );
  * </pre>
  *
  * @id.hint The ID of the document to retrieve.
  * @deserialize.hint Deserialize the JSON automatically for you and return the representation
  * @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
  * @inflateTo.hint The object that will be used to inflate the data with according to our conventions
  *
  * @return A struct with "CAS" and "value" keys.  If the ID doesn't exist, this method will return null.
  */
  public any function getWithCAS(
    required string id,
    boolean deserialize=true,
    struct deserializeOptions={},
    any inflateTo=""
  ) {
    // couchbase expects a target class to inflate the results to, in this case we just want the raw
    // result and we will handle the deserialization on our side
    var document = newEmptyDocument( argumentCollection=arguments ).create(
      variables.util.normalizeID( arguments.id )
    );
    var result = "";
    try {
      result = variables.couchbaseBucket.get( document );
    }
    catch( any e ) {
      // basically an attempt was made to retrieve a legacy document that cannot be inflated
      // to the new Json*Document objects provided by the SDK.  try to get the document as a
      // legacy document
      if( e.type == "com.couchbase.client.java.error.TranscodingException" ) {
        arguments['legacy'] = true;
        // rebuild a new document shell
        document = newEmptyDocument( argumentCollection=arguments ).create(
          variables.util.normalizeID( arguments.id )
        );
        // try to get the results again
        result = variables.couchbaseBucket.get( document );
      }
      else {
        rethrow;
      }
    }
    if( !isNull( result ) ) {
      // build struct out.
      return {
        'expiry' = result.expiry(),
        'cas' = result.cas(),
        'value' = deserializeData(
          arguments.id,
          result.content(),
          arguments.inflateTo,
          arguments.deserialize,
          arguments.deserializeOptions
        )
      };
    }
  }

  /**
  * ( deprecated )
  * asyncGetWithCAS() is no longer supported
  */
  public any function asyncGetWithCAS( required string id ) {
    throw(
      message="async options not supported",
      detail="The asyncGetWithCAS method is not currently supported.",
      type="CouchbaseClient.NotSupported"
    );
  }

  /**
  * Obtain a value for a given ID and update the expiry time for the document at the same time.  This is useful for a sort of "last access timeout"
  * functionality where you don't want a document to timeout while it is still being accessed.
  *
  * <pre class='brush: cf'>
  * result = client.getAndTouch( 'brad' );
  * writeOutput( result.cas );
  * writeOutput( result.value );
  * </pre>
  *
  * @id.hint The ID of the document to retrieve.
  * @timeout.hint The expiration of the document in minutes
  * @deserialize.hint Deserialize the JSON automatically for you and return the representation
  * @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
  * @inflateTo.hint The object that will be used to inflate the data with according to our conventions
  *
  * @return A struct with "CAS" and "value" keys.  If the ID doesn't exist, this method will return null.
  */
  public any function getAndTouch(
    required string id,
    required numeric timeout,
    boolean deserialize=true,
    struct deserializeOptions={},
    any inflateTo=""
  ) {
    // couchbase expects a target class to inflate the results to, in this case we just want the raw
    // result and we will handle the deserialization on our side
    var document = newEmptyDocument( argumentCollection=arguments ).create(
      variables.util.normalizeID( arguments.id )
    );
    var result = "";
    try {
      result = variables.couchbaseBucket.getAndTouch( document );
    }
    catch( any e ) {
      // basically an attempt was made to retrieve a legacy document that cannot be inflated
      // to the new Json*Document objects provided by the SDK.  try to get the document as a
      // legacy document
      if( e.type == "com.couchbase.client.java.error.TranscodingException" ) {
        arguments['legacy'] = true;
        // rebuild a new document shell
        document = newEmptyDocument( argumentCollection=arguments ).create(
          variables.util.normalizeID( arguments.id )
        );
        // try to get the results again
        result = variables.couchbaseBucket.getAndTouch( document );
      }
      else {
        rethrow;
      }
    }
    if( !isNull( result ) ) {
      // build struct out.
      return {
        'expiry' = result.expiry(),
        'cas' = result.cas(),
        'value' = deserializeData(
          arguments.id,
          result.content(),
          arguments.inflateTo,
          arguments.deserialize,
          arguments.deserializeOptions
        )
      };
    }
  }

  /**
  * Obtain a value for a given ID and update the expiry time for the document at the same time.  This is useful for a sort of "last access timeout"
  * functionality where you don't want a document to timeout while it is still being accessed.
  *
  * <pre class='brush: cf'>
  * future = client.asyncGetAndTouch( 'brad' );
  * </pre>
  *
  * @id.hint The ID of the document to retrieve.
  * @timeout.hint The expiration of the document in minutes
  *
  * @return A Future object ( net.spy.memcached.internal.OperationFuture ) that retrieves a CASValue class that you can use to get the value and cas of the object.
  */
  public any function asyncGetAndTouch(
    required string id,
    required numeric timeout
  ) {
    throw(
      message="async options not supported",
      detail="The asyncGetAndTouch method is not currently supported.",
      type="CouchbaseClient.NotSupported"
    );
  }

  /**
  * Get an object from couchbase with its CAS value and lock it, returns null if not found.  This method is meant to be used in conjunction with replaceWithCAS and unlock.
  * Once a document has been locked it cannot be updated by other clients and must be updated with the CAS value by the current client. A document cannot be locked for
  * more than 30 seconds.
  *
  * IMPORTANT: A locked document cannot be re-retrieved during a lock it can only be updated via CAS or unlocked
  *
  * <pre class='brush: cf'>
  * result = client.getAndLock( 'aaron' );
  * writeOutput( result.cas );
  * writeOutput( result.value );
  * </pre>
  *
  * @id.hint The ID of the document to retrieve.
  * @deserialize.hint Deserialize the JSON automatically for you and return the representation
  * @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
  * @inflateTo.hint The object that will be used to inflate the data with according to our conventions
  *
  * @return A struct with "CAS" and "value" keys.  If the ID doesn't exist, this method will return null.
  */
  public any function getAndLock(
    required string id,
    numeric lockTime=30,
    boolean deserialize=true,
    struct deserializeOptions={},
    any inflateTo=""
  ) {
    if( arguments.lockTime > 30 ) {
      throw(
        message="Invalid lockTime",
        detail="The lockTime value cannot exceed 30 seconds",
        type="CouchbaseClient.GetAndLockTimeException"
      );
    }
    // couchbase expects a target class to inflate the results to, in this case we just want the raw
    // result and we will handle the deserialization on our side
    var document = newEmptyDocument( argumentCollection=arguments ).create(
      variables.util.normalizeID( arguments.id )
    );
    var result = "";
    try {
      result = variables.couchbaseBucket.getAndLock(
        document,
        javaCast( "int", arguments.lockTime )
      );
    }
    catch( any e ) {
      // catch any exceptions to see if it is a lock exception
      // locked documents cannot be re-retrieved until the lockTime has exceeded
      // or the document has been updated with a CAS value or it explicly unlocked
      if( e.type == "com.couchbase.client.java.error.TemporaryLockFailureException" ) {
        throw(
          message="Document Locked",
          detail="The document has been locked and cannot be retrieved at this time",
          type="CouchbaseClient.LockedDocument"
        );
      }
      // basically an attempt was made to retrieve a legacy document that cannot be inflated
      // to the new Json*Document objects provided by the SDK.  try to get the document as a
      // legacy document
      if( e.type == "com.couchbase.client.java.error.TranscodingException" ) {
        arguments['legacy'] = true;
        // try to get the results again
        result = this.getAndLock( argumentCollection=arguments );
      }
    }
    if( !isNull( result ) ) {
      // build struct out.
      return {
        'expiry' = result.expiry(),
        'cas' = result.cas(),
        'value' = deserializeData(
          arguments.id,
          result.content(),
          arguments.inflateTo,
          arguments.deserialize,
          arguments.deserializeOptions
        )
      };
    }
  }

  /**
  * Unlocks a locked document
  *
  * <pre class='brush: cf'>
  * result = client.getAndLock( 'aaron' );
  * writeOutput( result.cas );
  * writeOutput( result.value );
  * ...
  * unlockSuccess = client.unlock( 'aaron' );
  * </pre>
  *
  * @id.hint The ID of the document to unlock.
  * @cas.hint CAS value retrieved via getAndLock()
  * @return A boolean indicating whether the unlock was successful or not
  */
  public boolean function unlock( required string id, required numeric cas ) {
    return variables.couchbaseBucket.unlock(
      variables.util.normalizeID( arguments.id ),
      javaCast( "long", arguments.cas )
    );
  }

  /**
  * Get an object from a couchbase replica by the ID.  This method will deserialize object automatically and optionally inflate the data into a CFC.
  *
  * <pre class='brush: cf'>
  * person = client.getFromReplica( 'aaron', 'ALL' );
  * </pre>
  *
  * @id.hint The ID of the document to retrieve.
  * @deserialize.hint Deserialize the JSON automatically for you and return the representation
  * @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
  * @inflateTo.hint The object that will be used to inflate the data with according to our conventions
  *
  * @return An array of objects from each replica
  */
  public array function getFromReplica(
    required string id,
    replicaMode="ALL",
    boolean deserialize=true,
    struct deserializeOptions={},
    any inflateTo=""
  ) {
    // make sure the consistency is valid
    if( !listFindNoCase( "ALL,ONE,TWO,THREE", arguments.replicaMode ) ) {
      throw(
        message="Invalid replicaMode Value",
        detail="Invalid replicaMode value, valid values are: ALL, ONE, TWO, THREE",
        type="CouchbaseClient.GetReplicaException"
      );
    }
    var document = newJava( "com.couchbase.client.java.document.RawJsonDocument" ).create( variables.util.normalizeID( arguments.id ) );
    var results = variables.couchbaseBucket.getFromReplica(
      document,
      this.replicaMode[uCase( arguments.replicaMode )]
    );
    // loop over all of the results
    var cfresults = [];
    var i = 0;
    for( var doc in results ) {
      i++;
      cfresults[i] = deserializeData(
        arguments.id,
        // com.couchbase.client.java.document.JsonDocument
        doc.content(),
        arguments.inflateTo,
        arguments.deserialize,
        arguments.deserializeOptions
      );
    }
    return cfresults;
  }

  /**
  * Shutdown the native client connection
  *
  * <pre class='brush: cf'>
  * client.shutdown( 10 );
  * </pre>
  *
  * @timeout.hint The timeout in seconds, we default to 10 seconds
  *
  * @return A refernce to "this" CFC
  */
  public CouchbaseClient function shutdown( numeric timeout=10 ) {
    // close the connection to the bucket
    variables.couchbaseBucket.close( javaCast( "long", arguments.timeout ), variables.timeUnit.SECONDS );
    // close the connection to the cluster
    variables.couchbaseCluster.disconnect( javaCast( "long", arguments.timeout ), variables.timeUnit.SECONDS );
    return this;
  }

  /**
  * Flush all caches from all servers with a delay of application.
  *
  * <pre class='brush: cf'>
  * client.flush( 5 );
  * </pre>
  *
  * @delay.hint The period of time to delay, in seconds
  *
  * @return A Java future object. ( net.spy.memcached.internal.OperationFuture )
  */
  public any function flush( numeric delay=0 ) {
    return variables.couchbaseBucket.bucketManager().flush( javaCast( "long", arguments.delay ), variables.timeUnit.SECONDS );
  }

  /**
  * Get all of the stats from all of the servers in the cluster.
  * Information on stats available here: http://www.couchbase.com/docs/couchbase-manual-1.8/cbstats-all-bucket-info.html
  *
  * <pre class='brush: cf'>
  * clusterStats = client.getStats();
  * </pre>
  *
  * @username A valid username for the admin console
  * @password A valid password for the admin console
  * @return An array for each server in the cluster with a structure of stats
  */
  public array function getStats( required string username, required string password ) {
    var stats = deserializeJSON(
      variables.couchbaseCluster.clusterManager(
        arguments.username,
        arguments.password
      )
        .info()
          .raw()
            .toString()
    );
    return stats.nodes;
  }

  /**
  * Get an aggregate of a single stat aggregated across all servers in the cluster.  This method saves you the trouble of calling getStats() and manually
  * looping over each server to add up the totals.  val() is called on each value, so stats which are not numeric will simply return 0.
  * This only works for numeric stats that are additive across the cluster such as "get_misses" or "curr_items".  A stat such as "time" would
  * not make sense even though it is numeric, since adding epoch dates serves no purpose.
  * <p>
  * Information on stats available here: http://www.couchbase.com/docs/couchbase-manual-1.8/cbstats-all-bucket-info.html
  *
  * <pre class='brush: cf'>
  * stats = client.getAggregateStat( 'curr_items' );
  * </pre>
  *
  * @username A valid username for the admin console
  * @password A valid password for the admin console
  * @stat.hint The key of an individual stat to return
  *
  * @return An integer representing the aggregation of the stat specified acrossed the cluster.
  */
  public numeric function getAggregateStat(
    required string username,
    required string password,
    required string stat
  ) {
    var nodes = getStats( arguments.username, arguments.password );
    var statValue = 0;
    // Loop over all the servers and add up the values if they exist for that server
    for( var node in nodes ) {
      // if the stat exists in the top-level structure
      if( structKeyExists( node, arguments.stat ) && isNumeric( node[arguments.stat] ) ) {
        statValue += val( serverStats[arguments.stat] );
      }
      // if the stat is in the interestingStats property
      else if( structKeyExists( node.interestingStats, arguments.stat ) && isNumeric( node.interestingStats[arguments.stat] ) ) {
        statValue += val( node.interestingStats[arguments.stat] );
      }
      // if the stat is in the systemStats property
      else if( structKeyExists( node.systemStats, arguments.stat ) && isNumeric( node.systemStats[arguments.stat] ) ) {
        statValue += val( node.systemStats[arguments.stat] );
      }
    }
    return statValue;
  }

  /**
  * Increment or Decrement the given counter, returning the new value.  This method is thread safe as it decrements and
  * retrives the value in a single operation as opposed to getting it, and then setting it again with subsequent calls.
  *
  * <pre class='brush: cf'>
  * newValue = client.decr( 'passesLeft', 1 );
  * </pre>
  *
  * @id.hint The id of the document to decrement
  * @value.hint The amount to decrement
  * @defaultValue.hint The default value ( if the counter does not exist, this defaults to 0 );
  * @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
  *
  * @return The new value, or -1 if we were unable to decrement or add
  */
  public any function counter(
    required string id,
    required numeric value,
    numeric defaultValue=0,
    numeric timeout
  ) {
    // default timeouts
    defaultTimeout( arguments );

    var document = variables.couchbaseBucket.counter(
      variables.util.normalizeID( arguments.id ),
      javaCast( "long", arguments.value ),
      javaCast( "long", arguments.defaultValue ),
      javaCast( "long", arguments.timeout )
    );
    return document.content();
  }

  /**
  * Increment or Decrement the given counter, returning the new value.  This method is thread safe as it decrements and
  * retrives the value in a single operation as opposed to getting it, and then setting it again with subsequent calls.
  *
  * <pre class='brush: cf'>
  * newValue = client.decr( 'passesLeft', 1 );
  * </pre>
  *
  * @id.hint The id of the document to decrement
  * @value.hint The amount to decrement
  * @defaultValue.hint The default value ( if the counter does not exist, this defaults to 0 );
  * @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
  *
  * @return A Java Observable ( rx.Observable )
  */
  public any function asyncCounter(
    required string id,
    required numeric value,
    numeric defaultValue=0,
    numeric timeout
  ) {
    throw(
      message="async options not supported",
      detail="The asyncCounter method is not currently supported.",
      type="CouchbaseClient.NotSupported"
    );
  }

  /**
  * ( deprecated )
  * decr() is no longer supported, it has been replaced with counter(), leaving here for backwards compatibility
  */
  public any function decr(
    required string id,
    required numeric value,
    numeric defaultValue=0,
    numeric timeout
  ) {
    // since it is being passed to counter the value needs to be negative
    arguments['value'] *= -1;
    return this.counter( argumentCollection=arguments );
  }

  /**
  * ( deprecated )
  * asyncDecr() is no longer supported, it has been replaced with asyncCounter(), leaving here for backwards compatibility
  */
  public any function asyncDecr(
    required string id,
    required numeric value,
    numeric defaultValue=0,
    numeric timeout
  ) {
    throw(
      message="async options not supported",
      detail="The asyncDecr method is not currently supported.",
      type="CouchbaseClient.NotSupported"
    );
  }

  /**
  * ( deprecated )
  * incr() is no longer supported, it has been replaced with counter(), leaving here for backwards compatibility
  */
  public any function incr(
    required string id,
    required numeric value,
    numeric defaultValue=0,
    numeric timeout
  ) {
    return this.counter( argumentCollection=arguments );
  }

  /**
  * ( deprecated )
  * asyncIncr() is no longer supported, it has been replaced with asyncCounter(), leaving here for backwards compatibility
  */
  public any function asyncIncr(
    required string id,
    required numeric value,
    numeric defaultValue=0,
    numeric timeout
  ) {
    throw(
      message="async options not supported",
      detail="The asyncDecr method is not currently supported.",
      type="CouchbaseClient.NotSupported"
    );
  }

  /**
  * Touch the given ID to reset its expiration time.
  *
  * <pre class='brush: cf'>
  * future = client.touch( 'sessionData', 30 );
  * </pre>
  *
  * @id.hint The id of the document to increment
  * @timeout.hint The expiration of the document in minutes
  *
  * @return A boolean indicating whether or not the touch was successful
  */
  public boolean function touch(
    required string id,
    required numeric timeout
  ) {
    // default the timeout
    defaultTimeout( arguments );
    var result = variables.couchbaseBucket.touch(
        javaCast( "string", variables.util.normalizeID( arguments.id ) ),
        javaCast( "int", arguments.timeout )
    );
    return result;
  }

  /**
  * Delete a value with durability options. The durability options here operate similarly to those documented in the set method.
  *
  * <pre class='brush: cf'>
  * client.remove( 'brad' );
  * </pre>
  *
  * @id The ID of the document to delete, or an array of ID's to delete
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  *
  * @return A structure of document IDs w/ boolean values or just a boolean whether or not the delete was successful
  */
  public any function remove(
    required any id,
    string persistTo,
    string replicateTo
  ) {
    arguments['id'] = variables.util.normalizeID( arguments.id );

    // default persist and replicate
    defaultPersistReplicate( arguments );

    // simple or array
		arguments['id'] = isSimpleValue( arguments.id ) ? listToArray( arguments.id ) : arguments.id;

    var results = {};
    // iterate over the results
    for( var document_id in arguments.id ) {
      try {
        variables.couchbaseBucket.remove(
          document_id,
          arguments.persistTo,
          arguments.replicateTo
        );
        // the operation returns the document that was deleted if we got here it was successful
        results[document_id] = true;
      }
      catch( any e ) {
        // if the document doesn't exist or the durability options couldn't be met set a false value for the key
        if( e.type == "com.couchbase.client.java.error.DocumentDoesNotExistException" || e.type == "com.couchbase.client.java.error.DurabilityException" ) {
          results[document_id] = false;
        }
        else {
          rethrow;
        }
      }
    }
    // if > 1 futures, return struct, else return the only one future
		return structCount( results ) > 1 ? results : results[ arguments.id[ 1 ] ];
  }

  /**
  * ( deprecated )
  * delete() is no longer supported, it has been replaced with remove(), leaving here for backwards compatibility
  */
  public any function delete(
    required any id,
    string persistTo,
    string replicateTo
  ) {
    return this.remove( argumentCollection=arguments );
  }

  /**
  * Determines whether or not a document exists in a bucket or not
  *
  * <pre class='brush: cf'>
  * exists = client.exists( 'aaron' );
  * </pre>
  *
  * @id.hint The ID of the document to delete, or an array of ID's to delete
  *
  * @return Boolean indicating the existence of a document
  */
  public boolean function exists( required any id ) {
    return variables.couchbaseBucket.exists( arguments.id );
  }

  /**
  * ( deprecated )
  * getDocStats() is no longer supported
  */
  public any function getDocStats( required any id ) {
   throw(
     message="getDocStats not supported",
     detail="The getDocStats method is not supported as it has been removed from the SDK.",
     type="CouchbaseClient.NotSupported"
    );
  }

  /**
  * Get the addresses of available servers.
  *
  * <pre class='brush: cf'>
  * serverArray = client.getAvailableServers();
  * </pre>
  *
  * @username A valid username for the admin console
  * @password A valid password for the admin console
  *
  * @return An array containing an item for each server in the cluster.  Servers are represented as a string containing their address produced via java.net.InetSocketAddress.toString()
  */
  public array function getAvailableServers( required string username, required string password ) {
    var stats = getStats( arguments.username, arguments.password );
    var servers = [];
    for( var node in stats ) {
      if( node.status == "healthy" && node.clusterMembership == "active" ) {
        arrayAppend( servers, node.hostname );
      }
    }
    return servers;
  }

  /**
  * Get the addresses of unavailable servers
  *
  * <pre class='brush: cf'>
  * serverArray = client.getUnAvailableServers();
  * </pre>
  *
  * @username A valid username for the admin console
  * @password A valid password for the admin console
  *
  * @return An array containing an item for each unavilable server in the cluster.  Servers are represented as a string containing their address produced via java.net.InetSocketAddress.toString() <br>If all servers are online, the array with be empty.
  */
  public array function getUnAvailableServers( required string username, required string password ) {
    var stats = getStats( arguments.username, arguments.password );
    var servers = [];
    for( var node in stats ) {
      if( node.status != "healthy" || node.clusterMembership != "active" ) {
        arrayAppend( servers, node.hostname );
      }
    }
    return servers;
  }

  /**
  * Get the Couchbase environment details
  *
  * <pre class='brush: cf'>
  * environment = client.getEnvironment();
  * </pre>
  *
  * @return A struct with information about the environment
  */
  public struct function getEnvironment() {
    var env = variables.couchbaseBucket.environment();
    var settings = {};
    settings['autoReleaseAfter'] = env.AUTORELEASE_AFTER;
    settings['bootstrapCarrierDirectPort'] = env.BOOTSTRAP_CARRIER_DIRECT_PORT;
    settings['bootstrapCarrierEnabled'] = env.BOOTSTRAP_CARRIER_ENABLED;
    settings['bootstrapCarrierSslPort'] = env.BOOTSTRAP_CARRIER_SSL_PORT;
    settings['bootstrapHttpDirectPort'] = env.BOOTSTRAP_HTTP_DIRECT_PORT;
    settings['bootstrapHttpEnabled'] = env.BOOTSTRAP_HTTP_ENABLED;
    settings['bootstrapHttpSslPort'] = env.BOOTSTRAP_HTTP_SSL_PORT;
    settings['bufferPoolingEnabled'] = env.BUFFER_POOLING_ENABLED;
    settings['computationPoolSize'] = env.COMPUTATION_POOL_SIZE;
    settings['connectTimeout'] = env.connectTimeout();
    settings['dcpEnabled'] = env.DCP_ENABLED;
    settings['disconnectTimeout'] = env.disconnectTimeout();
    settings['dnsSrvEnabled'] = env.dnsSrvEnabled();
    settings['ioPoolSize'] = env.IO_POOL_SIZE;
    settings['keepAliveInterval'] = env.KEEPALIVEINTERVAL;
    settings['keyValueEndpoints'] = env.KEYVALUE_ENDPOINTS;
    settings['kvTimeout'] = env.kvTimeout();
    settings['managementTimeout'] = env.managementTimeout();
    settings['maxRequestLifetime'] = env.MAX_REQUEST_LIFETIME;
    settings['mutationTokensEnabled'] = env.MUTATION_TOKENS_ENABLED;
    settings['observeIntervalDelay'] = env.OBSERVE_INTERVAL_DELAY;
    settings['packageNameAndVersion'] = env.PACKAGE_NAME_AND_VERSION;
    settings['queryEnabled'] = env.QUERY_ENABLED;
    settings['queryEndpoints'] = env.QUERY_ENDPOINTS;
    settings['queryPort'] = env.QUERY_PORT;
    settings['queryTimeout'] = env.queryTimeout();
    settings['reconnectDelay'] = env.RECONNECT_DELAY;
    settings['requestBufferSize'] = env.REQUEST_BUFFER_SIZE;
    settings['responseBufferSize'] = env.RESPONSE_BUFFER_SIZE;
    settings['retryDelay'] = env.RETRY_DELAY;
    settings['retryStrategy'] = env.RETRY_STRATEGY;
    settings['sdkPackageNameAndVersion'] = env.SDK_PACKAGE_NAME_AND_VERSION;
    settings['sslEnabled'] = env.SSL_ENABLED;
    settings['sslKeystoreFile'] = !isNull(env.SSL_KEYSTORE_FILE) ? env.SSL_KEYSTORE_FILE : "";
    settings['sslKeystorePassword'] = !isNull(env.SSL_KEYSTORE_PASSWORD) ? env.SSL_KEYSTORE_PASSWORD : "";
    // this is not a typo couchbase has a typo in their field
    settings['tcpNodelayEnabled'] = env.TCP_NODELAY_ENALED;
    settings['userAgent'] = env.USER_AGENT;
    settings['viewEndpoints'] = env.VIEW_ENDPOINTS;
    settings['viewTimeout'] = env.viewTimeout();
    return settings;
  }

  /**
  * Append to an existing value in the cache. If 0 is passed in as the CAS identifier ( default ), it will override the value on the server without performing the CAS check.
  * This method is considered a 'binary' method since it operates on binary data such as string or integers, not JSON documents
  *
  * <pre class='brush: cf'>
  * result = client.append( 'operationLog', 'This is a new log message#chr( 13 )##chr( 10 )#' );
  * </pre>
  *
  * @id.hint The unique id of the document whose value will be appended
  * @value.hint The value to append
  * @CAS.hint CAS identifier ( ignored in the ascii protocol )
  *
  * @return A Java instance of the document that was created as
  * - com.couchbase.client.java.document.LegacyDocument or
  * - com.couchbase.client.java.document.BinaryDocument or
  * - com.couchbase.client.java.document.StringDocument
  */
  public any function append(
    required string id,
    required any value,
    numeric cas,
    string persistTo,
    string replicateTo
  ) {
    // append operations are only supported on legacy documents
    arguments['legacy'] = true;
    // get a new document presentation
    var document = newPopulatedDocument( argumentCollection=arguments );
    // default persist and replicate
    defaultPersistReplicate( arguments );
    // append the document
    return variables.couchbaseBucket.append(
      document,
      arguments.persistTo,
      arguments.replicateTo
    );
  }

  /**
  * Prepend to an existing value in the cache. If 0 is passed in as the CAS identifier ( default ), it will override the value on the server without performing the CAS check.
  * This method is considered a 'binary' method since it operates on binary data such as string or integers, not JSON documents
  *
  * <pre class='brush: cf'>
  * result = client.append( 'operationLog', 'This is a new log message#chr( 13 )##chr( 10 )#' );
  * </pre>
  *
  * @id.hint The unique id of the document whose value will be appended
  * @value.hint The value to append
  * @CAS.hint CAS identifier ( ignored in the ascii protocol )
  *
  * @return A Java instance of the document that was created as
  * - com.couchbase.client.java.document.LegacyDocument or
  * - com.couchbase.client.java.document.BinaryDocument or
  * com.couchbase.client.java.document.StringDocument
  */
  public any function prepend(
    required string id,
    required any value,
    numeric cas,
    string persistTo,
    string replicateTo
  ) {
    // prepend operations are only supported on legacy documents
    arguments['legacy'] = true;
    // get a new document presentation
    var document = newPopulatedDocument( argumentCollection=arguments );
    // default persist and replicate
    defaultPersistReplicate( arguments );
    // prepend the document
    return variables.couchbaseBucket.prepend(
      document,
      arguments.persistTo,
      arguments.replicateTo
    );
  }

  /************************* VIEW INTEGRATION ***********************************/

  /**
  * Creates a new Java query object ( com.couchbase.client.protocol.views.Query ) that can be used to execute raw view queries.
  * You can pass an optional options struct with name-value pairs of simple query options.
  * <p>
  * http://www.couchbase.com/autodocs/couchbase-java-client-1.2.0/com/couchbase/client/protocol/views/Query.html
  *
  * <pre class='brush: cf'>
  * oQuery = client.newQuery(  { offset:10, limit:20, group:true, groupLevel:2 } );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document
  * @viewName.hint The name of the view to get
  * @options.hint A struct of query options, see http://www.couchbase.com/autodocs/couchbase-java-client-1.2.0/com/couchbase/client/protocol/views/Query.html for more information. This only does the simple 1 value options
  *
  * @return A Java query object ( com.couchbase.client.java.view.ViewQuery )
  */
  public any function newViewQuery(
    required string designDocumentName,
    required string viewName,
    struct options= {}
  ) {
    var viewQuery = newJava( "com.couchbase.client.java.view.ViewQuery" );
    arguments['options'] = variables.queryHelper.processOptions( arguments.options );
    // set the design document and view name
    viewQuery = viewQuery.from( arguments.designDocumentName, arguments.viewName );

    // set debug
    if( structKeyExists( arguments.options, "debug" ) ) {
      viewQuery = viewQuery.debug( javaCast( "boolean", arguments.options.debug ) );
    }
    // set descending
    if( structKeyExists( arguments.options, "descending" ) ) {
      viewQuery = viewQuery.descending( arguments.options.descending );
    }
    // set development
    if( structKeyExists( arguments.options, "development" ) ) {
      viewQuery = viewQuery.development( arguments.options.development );
    }
    // set the endKey
    if( structKeyExists( arguments.options, "endKey" ) ) {
      viewQuery = viewQuery.endKey( arguments.options.endKey );
    }
    // set the endKeyDocId
    if( structKeyExists( arguments.options, "endKeyDocId" ) ) {
      viewQuery = viewQuery.endKeyDocId( arguments.options.endKeyDocId );
    }
    // set the group
    if( structKeyExists( arguments.options, "group" ) ) {
      viewQuery = viewQuery.group( arguments.options.group );
    }
    // set the groupLevel
    if( structKeyExists( arguments.options, "groupLevel" ) ) {
      viewQuery = viewQuery.groupLevel( arguments.options.groupLevel );
    }
    // set includeDocs
    if( structKeyExists( arguments.options, "includeDocs" ) ) {
      viewQuery = viewQuery.includeDocs( javaCast( "boolean", arguments.options.includeDocs ) );
    }
    // set inclusiveEnd
    if( structKeyExists( arguments.options, "inclusiveEnd" ) ) {
      viewQuery = viewQuery.inclusiveEnd( arguments.options.inclusiveEnd );
    }
    // set the key
    if( structKeyExists( arguments.options, "key" ) ) {
      viewQuery = viewQuery.key( arguments.options.key );
    }
    // set the keys
    if( structKeyExists( arguments.options, "keys" ) ) {
      viewQuery = viewQuery.keys( arguments.options.keys );
    }
    // set the limit
    if( structKeyExists( arguments.options, "limit" ) ) {
      viewQuery = viewQuery.limit( arguments.options.limit );
    }
    // set reduce
    if( structKeyExists( arguments.options, "reduce" ) ) {
      viewQuery = viewQuery.reduce( arguments.options.reduce );
    }
    // set skip
    if( structKeyExists( arguments.options, "skip" ) ) {
      viewQuery = viewQuery.skip( arguments.options.skip );
    }
    // set stale
    if( structKeyExists( arguments.options, "stale" ) ) {
      viewQuery = viewQuery.stale( arguments.options.stale );
    }
    // set startKey
    if( structKeyExists( arguments.options, "startKey" ) ) {
      viewQuery = viewQuery.startKey( arguments.options.startKey );
    }
    // set startKeyDocId
    if( structKeyExists( arguments.options, "startKeyDocId" ) ) {
      viewQuery = viewQuery.startKeyDocId( arguments.options.startKeyDocId );
    }
    return viewQuery;
  }

  /**
  * ( deprecated )
  * newQuery() is no longer supported, it has been replaced with newViewQuery() and newN1qlQuery, leaving here for backwards compatibility
  */
  public any function newQuery(
    string designDocumentName,
    string viewName,
    struct options={},
    string type="view",
    string statement,
    string parameters
  ) {
    if( arguments.type == "view" ) {
      return newViewQuery( argumentCollection=arguments );
    }
    else if( arguments.type == "n1ql" ) {
      return newViewQuery( argumentCollection=arguments );
    }
  }

  /**
  * Performs a Couchbase View Query or N1QL Query
  * The default structure for views is in tact added new properties for n1ql queries
  * See the viewQuery and n1qlQuery methods for parameter descriptions
  */
  public any function query(
    string designDocumentName,
    string viewName,
    any options={},
    boolean deserialize=true,
    struct deserializeOptions={},
    any inflateTo="",
    any filter,
    any transform,
    string returnType="array",
    string type="view",
    string statement,
    any parameters
  ) {
    // the sdk supports both View Queries and N1QL queries from the view method
    if( arguments.type == "n1ql" ) {
      return n1qlQuery( argumentCollection=arguments );
    }
    else {
      return viewQuery( argumentCollection=arguments );
    }
  }

  /**
  * Queries a Couchbase view using the options supplied.
  *<p>
  * Valid options are:
  *<p>
  * <ul>
  * <li><b>sortOrder</b> - Specifies the direction to sort the results based on the map function's "key" value.  Valid values are ASC and DESC.</li>
  * <li><b>limit</b> - Number of records to return</li>
  * <li><b>offset</b> - Number of records to skip when returning</li>
  * <li><b>reduce</b> - Flag to control whether the reduce portion of the view is run. If false, only the results of the map function are returned.</li>
  * <li><b>includeDocs</b> - Specifies whether or not to include the entire document in the results or just the key names. Default is false.</li>
  * <li><b>startkey</b> - Specify the start of a range of keys to return.  This value needs to be the same data type as the key in your view's map function.  If your view has a string for the key, pass in a string here.  If your key is an array of values, pass in an array of values.</li>
  * <li><b>endkey</b> - Specify the end of a range of keys to return.  This value needs to be the same data type as the key in your view's map function.  If your view has a string for the key, pass in a string here.  If your key is an array of values, pass in an array of values.</li>
  * <li><b>inclusiveEnd</b> - Use this when specifying an endKey parameter. Flag to control whether the endKey is inclusive or not.</li>
  * <li><b>startkeyDocID</b> - If you have specified a startKey AND there is more than one record in the view results that share that key, this will specify what ID to start at when returning records.  This input is ignored when not using startKey.</li>
  * <li><b>endKeyDocID</b> - If you have specified an endKey AND there is more than one record in the view results that share that key, this will specify what ID to end at when returning records.  This input is ignored when not using endKey.</li>
  * <li><b>group</b> - Flag to control whether the results of the reduce function are grouped.  If no groupLevel is specified, only one row will be returned.</li>
  * <li><b>groupLevel</b> - Number representing what level of the map key to group at ( Keys can be complex ).  If the key is simple, this parameter does nothing.</li>
  * <li><b>key</b> - The key of a single record to return.  For complex keys, pass the key as an array.</li>
  * <li><b>keys</b> - An array of keys to return.  For complex keys, pass each key as an array.</li>
  * <li><b>stale</b> - Specifies if stale data can be returned with the view.  Possible values are:
  *   <ul>
  *      <li><b>"TRUE"</b> ( default ) - stale data is ok
  *      <li><b>"FALSE"</b> - force index of view
  *      <li><b>"UPDATE_AFTER"</b> - potentially returns stale data, but starts an asynch re-index.</li>
  *   </ul>
  *   </li>
  * <li><b>debug</b> - Java SDK will log debugging information about the query</li>
  * </ul>
  * <p>
  * The options struct maps to the set of options found
  * in the native Couchbase query object ( com.couchbase.client.protocol.views.Query )
  * See http://www.couchbase.com/autodocs/couchbase-java-client-1.2.0/com/couchbase/client/protocol/views/Query.html
  *
  * <pre class='brush: cf'>
  * results = client.query( designDocumentName='beer', viewName='brewery_beers', options= { limit: 20, stale: 'OK' } );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document
  * @viewName.hint The name of the view to get
  * @options.hint The query options to use for this query. This can be a structure of name-value pairs or an actual Couchbase query options object usually using the 'newQuery()' method.
  * @deserialize.hint If true, it will deserialize the documents if they are valid JSON, else they are ignored.
  * @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
  * @inflateTo.hint A path to a CFC or closure that produces an object to try to inflate the document results on NON-Reduced views only!
  * @filter.hint A closure or UDF that must return boolean to use to filter out results from the returning array of records, the closure receives a struct that has id, document, key, and value: function( row ). A true will add the row to the final results.
  * @transform.hint A closure or UDF to use to transform records from the returning array of records, the closure receives a struct that has id, document, key, and value: function( row ). Since the struct is by reference, you do not need to return anything.
  * @returnType.hint The type of return for us to return to you. Available options: native, iterator, array. By default we use the cf type which uses transformations, automatic deserializations and inflations.
  *
  * @return If returnType is "array", will return an array of structs where each struct represents a record of output from the view.  <br>Each struct contains the following items: id, document, key, value  <br>If returnType is native, a Java ViewResponse object will be returned ( com.couchbase.client.protocol.views.ViewResponse )  <br>If returnType is iterator, a Java iterator object will be returned
  */
  public any function viewQuery(
    required string designDocumentName,
    required string viewName,
    any options={},
    boolean deserialize=true,
    struct deserializeOptions={},
    any inflateTo="",
    any filter,
    any transform,
    string returnType="array"
  ) {
    // if options is struct, then build out the query, else use it as an object.
    var oQuery = newViewQuery( arguments.designDocumentName, arguments.viewName, arguments.options );
    var results = rawQuery( oQuery );

    // should this throw or return an empty array?
    if( !results.success() ) {
      throw(
        message="Query Failed",
        detail="The query failed to execute",
        type="CouchbaseClient.ViewException"
      );
    }
    // Native return type?
    if( arguments.returnType == "native" ) {
      return results;
    }

    // Iterator results?
    if( arguments.returnType == "iterator" ) {
      return results.iterator();
    }

    // iterate and build it out with or without desrializations
    var iterator = results.iterator();
    var cfresults = [];
    while( iterator.hasNext() ) {
      var row = iterator.next();
      // if there is no id then the results are reduced
      var isReduced = isNull( row.id() );
      // if there is no id there will be no document
      var hasDocs = !isReduced && !isNull( row.document() );
      /**
      * ID: The id of the document in Couchbase, but only available if the query is NOT reduced
      * Document: Only available if the query is NOT reduced
      * Key: This is always available, but null if the query has been reduced, If un-redunced it is the first value passed into emit()
      * Value: This is always available. If reduced, this is the value returned by the reduce(), if not reduced it is the second value passed into emit()
      **/
      var document = {
        'id' = "",
        'document' = "",
        'key' = "",
        'value' = ""
      };
      // Add value if not null
      if( !isNull( row.value() ) ) {
        document['value'] = row.value();
      }

      // Add key if not null
      if( !isNull( row.key() ) ) {
        document['key'] = row.key().toString();
      }

      // check for reduced
      if( !isReduced ) {
        document['id'] = row.id();
      }

      // Did we get a document or none?
      if( hasDocs && structKeyExists( arguments.options, "includeDocs" ) && arguments.options.includeDocs ) {
        document['document'] = deserializeData(
          document.id,
          row.document().content(),
          arguments.inflateTo,
          arguments.deserialize,
          arguments.deserializeOptions
        );
      }

      // Do we have a transformer?
      if( structKeyExists( arguments, "transform" ) && isClosure( arguments.transform ) ) {
        arguments.transform( document );
      }

      // Do we have a filter?
      if(
        !structKeyExists( arguments, "filter" ) ||
        ( isClosure( arguments.filter ) && arguments.filter( document ) )
      ) {
        arrayAppend( cfresults, document );
      }
    }
    return cfresults;
  }

  /**
  * Queries a Couchbase view.
  * See: http://www.couchbase.com/autodocs/couchbase-java-client-1.2.0/com/couchbase/client/protocol/views/ViewResponse.html
  *
  * <pre class='brush: cf'>
  * query = client.newQuery(  { limit: 20, stale: 'OK' } );
  * view = client.getView( 'beer', 'brewery_beers' );
  * results = client.rawQuery( view, query );
  * </pre>
  *
  * @query.hint A couchbase query object ( com.couchbase.client.java.view.ViewQuery, com.couchbase.client.java.view.SpatialViewQuery, or )
  *
  * @return A raw Java View result object. Can be
  */
  public any function rawQuery( required any queryObject ) {
    return variables.couchbaseBucket.query( arguments.queryObject );
  }

  /**
  * Invalidates and clears the internal query cache. This method can be used to explicitly clear the internal N1QL query cache. This
  * cache will be filled with non-adhoc query statements ( query plans ) to speed up those subsequent executions.
  * Triggering this method will wipe out the complete cache, which will not cause an interruption but rather all
  * queries need to be re-prepared internally. This method is likely to be deprecated in the future once the
  * server side query engine distributes its state throughout the cluster.
  *
  * <pre class='brush: cf'>
  * entries = client.invalidateQueryCache();
  * </pre>
  *
  * @return The number of entries in the cache before it was cleared out.
  */
  public numeric function invalidateQueryCache() {
    return variables.couchbaseBucket.invalidateQueryCache();
  }

  /**
  * Gets access to a view contained in a design document from the cluster
  * You would usually use this method if you need the raw Java object to do manual queries or updates on a view.
  *
  * <pre class='brush: cf'>
  * view = client.getView( 'beer', 'brewery_beers' );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document
  * @viewName.hint The name of the view to get
  * @development.hint Whether or not to get the development or production view
  *
  * @return A View Java object ( com.couchbase.client.java.view.DefaultView or com.couchbase.client.java.view.SpatialView ).
  */
  public any function getView(
    required string designDocumentName,
    required string viewName,
    boolean development=false
  ) {
    var designDocument = getDesignDocument( argumentCollection=arguments );
    var views = designDocument.views();
    for( var view in views ) {
      if( view.name() == arguments.viewName ) {
        return view;
      }
    }
  }

  /**
  * Queries a Couchbase Bucket using N1QL a SQL like syntax
  *<p>
  * Valid options are:
  *<p>
  * <ul>
  *  <li><b>adhoc</b> - A boolean to specify if this query is adhoc or not.  If it is not adhoc ( so performed often ), the client will try to perform optimizations transparently based on the server capabilities, like preparing the statement and then executing a query plan instead of the raw query.</li>
  *  <li>
  *    <b>consistency</b> - Sets scan consistency. Valid values are:
  *    <ul>
  *       <li>NOT_BOUNDED - This is the default ( for single-statement requests ). No timestamp vector is used in the index scan. This is also the fastest mode, because we avoid the cost of obtaining the vector, and we also avoid any wait for the index to catch up to the vector.</li>
  *       <li>REQUEST_PLUS - This implements strong consistency per request. Before processing the request, a current vector is obtained. The vector is used as a lower bound for the statements in the request. If there are DML statements in the request, RYOW is also applied within the request.</li>
  *       <li>STATEMENT_PLUS - This implements strong consistency per statement. Before processing each statement, a current vector is obtained and used as a lower bound for that statement.</li>
  *    </ul>
  *  </li>
  *  <li><b>maxParallelism</b> - Allows to override the default maximum parallelism for the query execution on the server side.</li>
  *  <li><b>scanWait</b> - Sets the maximum time in milliseconds the client is willing to wait for an index to catch up to the vector timestamp in the request.  If the NOT_BOUNDED scan consistency has been chosen, does nothing.</li>
  *  <li><b>serverSideTimeout</b> - Sets a maximum timeout for processing on the server side</li>
  *  <li><b>clientContextId</b> - Adds a client context ID to the request, that will be sent back in the response, allowing clients to meaningfully trace requests/responses when many are exchanged.</li>
  * </ul>
  * <p>
  * The options struct maps to the set of options found
  * in the native Couchbase query object ( com.couchbase.client.java.query.N1qlParams )
  * See http://docs.couchbase.com/sdk-api/couchbase-java-client-2.2.0/com/couchbase/client/java/query/N1qlParams.html
  *
  * http://docs.couchbase.com/files/Couchbase-N1QL-CheatSheet.pdf
  * http://developer.couchbase.com/documentation/server/4.0/n1ql/n1ql-language-reference/index.html
  *
  * <pre class='brush: cf'>
  * results = client.n1qlQuery(
  *   statement = "
  *     SELECT t.callsign, t.country, t.iata, t.icao, t.id, t.name, t.type
  *     FROM `travel-sample` AS t
  *     WHERE t.country = $1
  *     LIMIT 10
  *   ",
  *   parameters = ["United Kingdom"]
  * );
  * </pre>
  *
  * @statement.hint The N1QL/SQL statement
  * @parameters.hint An array of parameters or an object of named parameters
  * @options.hint The query options to use for this query. This can be a structure of name-value pairs or an actual Couchbase query options object usually using the 'newQuery()' method.
  * @deserialize.hint If true, it will deserialize the documents if they are valid JSON, else they are ignored.
  * @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
  * @inflateTo.hint A path to a CFC or closure that produces an object to try to inflate the document results on NON-Reduced views only!
  * @filter.hint A closure or UDF that must return boolean to use to filter out results from the returning array of records, the closure receives a struct that has id, document, key, and value: function( row ). A true will add the row to the final results.
  * @transform.hint A closure or UDF to use to transform records from the returning array of records, the closure receives a struct that has id, document, key, and value: function( row ). Since the struct is by reference, you do not need to return anything.
  * @returnType.hint The type of return for us to return to you. Available options: native, iterator, array. By default we use the cf type which uses transformations, automatic deserializations and inflations.
  *
  * @return If returnType is "struct", will return struct containing the results, requestID, signature, and metrics. <br>If returnType is native, a Java ViewResponse object will be returned ( com.couchbase.client.protocol.views.ViewResponse )  <br>If returnType is iterator, a Java iterator object will be returned
  */
  public any function n1qlQuery(
    required string statement,
    any parameters,
    struct options={},
    boolean deserialize=true,
    struct deserializeOptions={},
    any inflateTo="",
    any filter,
    any transform,
    string returnType="struct"
  ) {
    // build the query
    var n1qlQuery = newN1qlQuery( argumentCollection=arguments );

    // run the query
    var n1qlResult = variables.couchbaseBucket.query( n1qlQuery );

    // Native return type?
    if( arguments.returnType == "native" ) {
      return n1qlResult;
    }

    // Iterator results?
    if( arguments.returnType == "iterator" ) {
      return n1qlResult.iterator();
    }

    // build the output
    var cfresults = {
      'requestId' = n1qlResult.requestId(),
      'clientContextId' = n1qlResult.clientContextId(),
      'errors' = deserializeJSON( n1qlResult.errors().toString() ),
      'metrics' = deserializeJSON( n1qlResult.info().asJsonObject().toString() ),
      'results' = []
    };
    cfresults['success'] = arrayLen( cfresults.errors ) == 0;

    // if there were errors just return
    if( !cfresults.success ) {
      return cfresults;
    }

    // iterate and build it out with or without desrializations
    var iterator = n1qlResult.iterator();
    while( iterator.hasNext() ) {
      var row = iterator.next();
      var document = deserializeData(
        "",
        row.value().toString(),
        arguments.inflateTo,
        arguments.deserialize,
        arguments.deserializeOptions
      );

      // Do we have a transformer?
      if( structKeyExists( arguments, "transform" ) && isClosure( arguments.transform ) ) {
        document = arguments.transform( document );
      }

      // Do we have a filter?
      if(
        !structKeyExists( arguments, "filter" ) ||
        ( isClosure( arguments.filter ) && arguments.filter( document ) )
      ) {
        arrayAppend( cfresults.results, document );
      }
    }
    return cfresults;
  }

  /**
  * Creates a new Java query object ( com.couchbase.client.java.query.N1qlQuery ) that can be used to execute raw n1ql queries.
  * You can pass an optional options struct with name-value pairs of simple query options.
  * <p>
  *
  * <pre class='brush: cf'>
  * oQuery = client.n1qlQuery(
  *   statement = "
  *     SELECT t.callsign, t.country, t.iata, t.icao, t.id, t.name, t.type
  *     FROM `travel-sample` AS t
  *     WHERE t.country = $1
  *     LIMIT 10
  *   ",
  *   parameters = ["United Kingdom"]
  * );
  *
  * results = client.rawQuery( oQuery );
  * </pre>
  *
  * @statement.hint The N1QL/SQL statement
  * @parameters.hint An array of parameters or an object of named parameters
  * @options.hint The query options to use for this query. This can be a structure of name-value pairs or an actual Couchbase query options object usually using the 'newQuery()' method.
  *
  * @return A Java query object ( com.couchbase.client.java.query.N1qlQuery )
  */
  public any function newN1qlQuery(
    required string statement,
    any parameters,
    struct options= {}
  ) {
    var n1qlQuery = newJava( "com.couchbase.client.java.query.N1qlQuery" );

    // this isn't the best flow but based on the method signatures this will have to do for now
    if( structKeyExists( arguments, "parameters" ) ) {
      // we are performing a parameterized query with parameters
      n1qlQuery = n1qlQuery.parameterized(
        arguments.statement,
        variables.queryHelper.processN1qlParameters( arguments.parameters ),
        variables.queryHelper.processN1qlOptions( arguments.options )
      );
    }
    else {
      // we are performing a simple query without parameters
      n1qlQuery = n1qlQuery.simple(
        arguments.statement,
        variables.queryHelper.processN1qlOptions( arguments.options )
      );
    }
    return n1qlQuery;
  }

  /**
  * Gets all of the indexes for all buckets
  *
  * <pre class='brush: cf'>
  * indexes = client.getIndexes( 'beer', 'brewery_beers' );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document
  * @viewName.hint The name of the view to get
  * @development.hint Whether or not to get the development or production view
  * @timeout.hint The timeout in milliseconds
  *
  * @return A View Java object ( com.couchbase.client.java.view.DefaultView or com.couchbase.client.java.view.SpatialView ).
  */
  public array function getIndexes(
    required string bucket
  ) {
    return n1qlQuery(
      statement='
        SELECT datastore_id, id, index_key, keyspace_id, name, namespace_id, state, `using`
        FROM system:indexes
        WHERE keyspace_id = $1;
      ',
      parameters=[arguments.bucket]
    ).results;
  }

  /**
  * Gets access to a spatial view contained in a design document from the cluster.
  * You would usually use this method if you need the raw Java object to do manual queries or updates on a view.
  *
  * <pre class='brush: cf'>
  * spatialView = client.getSpatialView( 'myDoc', 'mySpatialView' );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document
  * @viewName.hint The name of the view to get
  *
  * @return A View Java object ( com.couchbase.client.protocol.views.SpatialView ).
  */
  public any function getSpatialView( required string designDocumentName, required string viewName ) {
    return variables.couchbaseBucket.getSpatialView( arguments.designDocumentName, arguments.viewName );
  }

  /**
  * Gets a design document.
  * The returned value will be null if it does not exist.  Names are case-sensitive.
  *
  * <pre class='brush: cf'>
  * designDocument = client.getDesignDocument( 'beer' );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document
  * @development.hint Whether or not to get the development or production view
  * @timeout.hint The timeout in milliseconds
  *
  * @return A DesignDocument Java object ( com.couchbase.client.java.view.DesignDocument ).
  */
  public any function getDesignDocument(
    required string designDocumentName,
    boolean development=false
  ) {
    return variables.couchbaseBucket
      .bucketManager()
        .getDesignDocument(
          arguments.designDocumentName,
          javaCast( "boolean", arguments.development )
        );
  }

  /**
  * Deletes a design document from the server
  *
  * <pre class='brush: cf'>
  * client.removeDesignDocument( 'beer' );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document
  * @development.hint Whether or not to get the development or production view
  * @timeout.hint The timeout in milliseconds
  *
  * @return True if successsful, false if unsuccessful
  */
  public boolean function removeDesignDocument(
    required string designDocumentName,
    boolean development=false

  ) {
    return variables.couchbaseBucket
      .bucketManager()
        .removeDesignDocument(
          arguments.designDocumentName,
          javaCast( "boolean", arguments.development )
        );
  }

  /**
  * ( deprecated )
  * deleteDesignDocument() is no longer supported, it has been replaced with removeDesignDocument(), leaving here for backwards compatibility
  */
  public boolean function deleteDesignDocument( required string designDocumentName ) {
    return removeDesignDocument( argumentCollection=arguments );
  }

  /**
  * Initializes a new design document Java object.  The design doc will have no views and will not be saved yet.
  *
  * <pre class='brush: cf'>
  * designDocument = client.newDesignDocument( 'mynewDoc' );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document to initialize
  *
  * @return An instance of com.couchbase.client.java.view.DesignDocument
  */
  public any function newDesignDocument( required string designDocumentName, required array views=[] ) {
    return newJava( "com.couchbase.client.java.view.DesignDocument" ).create(
      arguments.designDocumentName,
      arguments.views
    );
  }

  /**
  * Checks to see if a design document exists.
  *
  * <pre class='brush: cf'>
  * result = client.designDocumentExists( 'beer' );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document to check for
  * @development.hint Whether or not to get the development or production view
  *
  * @Return True if the design document is found and false if it is not found.
  */
  public boolean function designDocumentExists(
    required string designDocumentName,
    boolean development=false
  ) {
    return !isNull( getDesignDocument( argumentCollection=arguments ) );
  }

  /**
  * Checks to see if a view exists.
  * You can check for a view by name, but if you supply a map or reduce function, they will be checked as well.
  *
  * <pre class='brush: cf'>
  * result = client.viewExists( 'beer', 'brewery_beers' );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document to check for
  * @viewName.hint The name of the view to check for
  * @mapFunction.hint The map function to check for.  Must be an exact match.
  * @reduceFunction.hint The reduce function to check for.  Must be an exact match.
  * @development.hint Whether or not to get the development or production view
  * @timeout.hint The timeout in milliseconds
  *
  * @Return 0 if the design document doesn't exist as well as if the design document exists, but there is no view by that name.<br> If the view does exist, it will return the index of the view in the designDocument's view array.
  */
  public numeric function viewExists(
    required string designDocumentName,
    required string viewName,
    string mapFunction,
    string reduceFunction,
    boolean development=false
  ) {
    var designDocument = getDesignDocument( arguments.designDocumentName );
    // If the design doc doesn't exist, bail.
    if( isNull( designDocument ) ) {
      return 0;
    }
    // get the views for the design document
    var views = designDocument.views();
    var i = 0;
    // Search to see if this view is already in the design document
    for( var view in views ) {
      i++;
      // If we find it ( by name )
      if( view.name() == arguments.viewName ) {
        // If there was a mapFunction specified, enforce the match
        if( structKeyExists( arguments, "mapFunction" ) && arguments.mapFunction != view.map() ) {
          return 0;
        }
        // If there was a reduceFunction specified, enforce the match
        if( structKeyExists( arguments, "reduceFunction" ) && arguments.reduceFunction != view.reduce() ) {
          return 0;
        }
        // Passed all the tests
        return i;
      }
    }
    // Exhausted the array with no match
    return 0;
  }

  /**
  * Creates a new instance of a viewDesign Java object ( com.couchbase.client.protocol.views.ViewDesign )
  *
  * <pre class='brush: cf'>
  * viewDesign = client.newViewDesign( viewName, mapFunction, reduceFunction );
  * </pre>
  *
  * @viewName.hint The name of the view to be created
  * @mapFunction.hint The map function for the view represented as a string
  * @reduceFunction.hint The reduce function for the view represented as a string
  * @viewType.hint The type of view to create values are "default" or "spatial"
  *
  * @Return An instance of the Java class com.couchbase.client.java.view.DefaultView or com.couchbase.client.java.view.SpatialView
  */
  public any function newViewDesign(
    required string viewName,
    required string mapFunction,
    string reduceFunction="",
    string viewType="default"
  ) {
    var view = "";
    if( arguments.viewType == "default" ) {
      view = newJava( "com.couchbase.client.java.view.DefaultView" ).create(
        arguments.viewName,
        arguments.mapFunction,
        arguments.reduceFunction
      );
    }
    else if( arguments.viewType == "spatial" ) {
      view = newJava( "com.couchbase.client.java.view.SpatialView" ).create(
        arguments.viewName,
        arguments.mapFunction
      );
    }
    else {
      throw(
        message="Invalid viewType Value",
        detail="Invalid viewType value, valid values are: default, spatial",
        type="CouchbaseClient.ViewTypeException"
      );
    }

    return view;
  }

  /**
  * Asynchronously Saves a View.  Will save the view and or designDocument if they don't exist.  Will update if they already exist.  This method
  * will return immediatley, but the view probalby won't be available to query for a few seconds.
  *
  * <pre class='brush: cf'>
  * client.asyncSaveView(
  * &nbsp;&nbsp;'manager',
  * &nbsp;&nbsp;'listBreweries',
  * &nbsp;&nbsp;'function ( doc, meta )  {
  * &nbsp;&nbsp;if ( doc.type == ''brewery'' )  {
  * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;emit( doc.name, null );
  * &nbsp;&nbsp;&nbsp;&nbsp;}
  * &nbsp;&nbsp;}',
  * &nbsp;&nbsp;'_count'
  * );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document for the view to be saved under.  The design document will be created if neccessary
  * @viewName.hint The name of the view to be saved
  * @mapFunction.hint The map function for the view represented as a string
  * @reduceFunction.hint The reduce function for the view represented as a string
  * @development.hint Whether or not to create the view in development or production
  * @viewType.hint The type of view to create values are "default" or "spatial"
  *
  * @Return True if the view was saved, false if no save occurred due to the view already existing.
  */
  public any function asyncSaveView(
    required string designDocumentName,
    required string viewName,
    required string mapFunction,
    string reduceFunction = "",
    boolean development=false,
    string viewType="default"
  ) {

    // This is required to clean up carriage returns
    arguments['mapFunction'] = variables.util.normalizeViewFunction( arguments.mapFunction );
    arguments['reduceFunction'] = variables.util.normalizeViewFunction( arguments.reduceFunction );

    // If this exact view already exists, we've nothing to do here
    if( viewExists( argumentCollection=arguments ) ) {
      return false;
    }

    // get the design document
    var designDocument = getDesignDocument( arguments.designDocumentName );
    // if designDocument is null create it
    if( isNull( designDocument ) ) {
      designDocument = newDesignDocument( arguments.designDocumentName );
    }

    // Create a representation of our new view
    var viewDesign = newViewDesign( arguments.viewName, arguments.mapFunction, arguments.reduceFunction );
    // get the views
    var views = designDocument.views();
    // Check for this view by name ( A less specific check than the one at the top of this method )
    var matchIndex = viewExists( arguments.designDocumentName, arguments.viewName );
    // And update or add it into the array as neccessary
    if( matchIndex ) {
      // Update existing
      views[matchIndex] = viewDesign;
    }
    else  {
      // Insert new
      views.add( viewDesign );
    }
    // recreate the entire design document with the new view
    designDocument = newDesignDocument( arguments.designDocumentName, views );
    // create or update the design document
    variables.couchbaseBucket
      .bucketManager()
        .upsertDesignDocument(
          designDocument,
          javaCast( "boolean", arguments.development )
        );
    return true;
  }

  /**
  * Saves a View.  Will save the view and or designDocument if they don't exist.  Will update if they already exist.
  *
  * <pre class='brush: cf'>
  * client.saveView(
  * &nbsp;&nbsp;'manager',
  * &nbsp;&nbsp;'listBreweries',
  * &nbsp;&nbsp;'function ( doc, meta )  {
  * &nbsp;&nbsp;if ( doc.type == ''brewery'' )  {
  * &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;emit( doc.name, null );
  * &nbsp;&nbsp;&nbsp;&nbsp;}
  * &nbsp;&nbsp;}',
  * &nbsp;&nbsp;'_count'
  * &nbsp;&nbsp;20
  * );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document for the view to be saved under.  The design document will be created if neccessary
  * @viewName.hint The name of the view to be saved
  * @mapFunction.hint The map function for the view represented as a string
  * @reduceFunction.hint The reduce function for the view represented as a string
  * @waitFor.hint How many seconds to wait for the view to save before giving up.  Defaults to 20, but may need to be higher for larger buckets.
  * @development.hint Whether or not to create the view in development or production
  * @viewType.hint The type of view to create values are "default" or "spatial"
  *
  * @Return True when the view is ready.  If the view is still not accessable after the number of seconds specified in the "waitFor" parameter, the method will return false.
  */
  public boolean function saveView(
    required string designDocumentName,
    required string viewName,
    required string mapFunction,
    string reduceFunction="",
    waitFor=20,
    boolean development=false,
    string viewType="default"
  ) {
    // save the view
    var viewSaved = asyncSaveView( argumentCollection=arguments );

    // Bail now if no save actually occurred
    if( !viewSaved ) {
      return true;
    }

    // View creation and population is asynchronous so we'll wait a while until it's ready.
    var attempts = 0;
    while( ++attempts <= arguments.waitFor ) {
      try {
        // Access the view
        this.query(
          designDocumentName=arguments.designDocumentName,
          viewName=arguments.viewName,
          options= {
            limit = 20,
            stale = "FALSE"
          }
        );
        // The view is ready to be used!
        return true;
      }
      catch( Any e )  {
        // Wait 1 second before trying again
        sleep( 1000 );
      }
    }

    // We've given up and the view never worked. There could be a problem, but most
    // likely the bucket just isn't finished indexing
    return false;

  }

  /**
  * Deletes a View.  Will delete the view from the designDocument if it exists.
  *
  * <pre class='brush: cf'>
  * client.deleteView( 'myDoc', 'myView' );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document for the view to be deleted from
  * @viewName.hint The name of the view to be deleted from
  * @development.hint Whether or not to get the development or production view
  * @removeIfEmpty.hint If there are no views should the design doc be created as empty or deleted?
  *
  * @viewName.hint The name of the view to be created
  */
  public void function deleteView(
    required string designDocumentName,
    required string viewName,
    boolean development=false,
    removeIfEmpty=true
  ) {
    // Check for this view by name
    var matchIndex = viewExists( arguments.designDocumentName, arguments.viewName );

    // Only bother continuing if it exists
    if( matchIndex ) {
      var designDocument = getDesignDocument( arguments.designDocumentName );
      var views = designDocument.views();

      // Remove the view from the array
      arrayDeleteAt( views, matchIndex );

      if( !arrayLen( views ) && arguments.removeIfEmpty ) {
        this.removeDesignDocument( argumentCollection=arguments );
      }
      else {
        // recreate the entire design document with the view removed
        designDocument = newDesignDocument( arguments.designDocumentName, views );
        // create or update the design document
        variables.couchbaseBucket
          .bucketManager()
            .upsertDesignDocument(
              designDocument,
              javaCast( "boolean", arguments.development )
            );
      }
    }
    return;
  }

  /**
  * Publishes a design document from development to production
  *
  * <pre class='brush: cf'>
  * client.publishDesignDocument( 'docName' );
  * </pre>
  *
  * @designDocumentName.hint The name of the design document for the view to be deleted from
  * @overwrite.hint Whether or not to overwrite the design document if it exists
  *
  * @viewName.hint Whether or not the design document was published successfully
  */
  public boolean function publishDesignDocument(
    required string designDocumentName,
    required boolean overwrite=false
  ) {
    var published = true;
    try {
      variables.couchbaseBucket
        .bucketManager()
          .publishDesignDocument(
            arguments.designDocumentName,
            javaCast( "boolean", arguments.overwrite )
          );
    }
    catch( any e ) {
      // if there was a timeout exception or the design document already exists
      if(
        e.type == "java.util.concurrent.TimeoutException" ||
        e.type == "com.couchbase.client.java.error.DesignDocumentAlreadyExistsException"
      ) {
        published = false;
      }
      else {
        rethrow;
      }
    }
    return published;
  }


  /************************* SERIALIZE/DESERIALIZE INTEGRATION ***********************************/

  /**
  * Deserializes an incoming data string via JSON and according to our rules. It can also accept an optional
  * inflateTo parameter wich can be an object we should inflate our data to.
  *
  * @id.hint The ID of the document being deserialized
  * @data.hint A JSON document to deserialize according to our rules
  * @inflateTo.hint The object that will be used to inflate the data with according to our conventions
  * @deserialize.hint The boolean value that marks if we should deserialize or not. Default is true
  * @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
  *
  * @Return The deserialized data
  */
  private any function deserializeData(
    required string id,
    required string data,
    any inflateTo="",
    boolean deserialize=true,
    struct deserializeOptions= {}
  ) {
    if( arguments.deserialize ) {
      return variables.dataMarshaller
        .deserializeData(
          arguments.id,
          arguments.data,
          arguments.inflateTo,
          arguments.deserializeOptions
        );
    }
    else {
      return arguments.data;
    }
  }

  /**
  * Serializes incoming data according to our rules.
  *
  * @data.hint The data to serialize
  *
  * @Return A string representation, usually JSON.
  */
  public string function serializeData( required any data ) {
    // Go to data marshaler
    return variables.dataMarshaller.serializeData( arguments.data );
  }

  /************************* JAVA INTEGRATION ***********************************/

  /**
  * Get the java loader instance
  *
  * @Return The javaLoader CFC.
  */
  public any function getJavaLoader() {
    if( !structKeyExists( server, variables.javaLoaderID ) ) {
      loadSDK();
    }
    return server[variables.javaLoaderID];
  }

  /**
  * Get a java class using either the JavaLoader or createOject() based on the "useClassloader" config value.
  * You will need to call init() if you want to run the class constructor and get an instance of it.
  *
  * @className.hint The class to get
  *
  * @Return The java class specified.
  */
  public any function newJava( required string className ) {
      return ( variables.couchbaseConfig.getUseClassloader() ? getJavaLoader().create( arguments.className ) : createObject( "java", arguments.className ) );
  }

  /************************* PRIVATE ***********************************/

  /**
  * Build the data marshaller
  *
  * @config.hint The CFCouchbase config object
  *
  * @Return The data marshaller
  */
  private any function buildDataMarshaller( required any config  ) {
    var marshaller = arguments.config.getDataMarshaller();
    // Build the data marshaller
    if( isSimpleValue( marshaller ) && len( marshaller ) ) {
      return new "#marshaller#"();
    }
    else if( isObject( marshaller ) ) {
      return marshaller;
    }
    else  {
      // build core marshaller.
      return new data.CoreMarshaller();
    }
  }

  /**
  * Build a couchbase connection client according to config and returns the raw java connection client object
  *
  * @config.hint The CFCouchbase config object
  *
  * @Return The java CouchbaseClient class ( com.couchbase.client.java.CouchbaseBucket ).
  */
  private any function buildCouchbaseClient( required any config ) {
    // get config options
    var configData = arguments.config.getMemento();
    // cleanup server URIs
    var servers = variables.util.formatServers( configData.servers );
    // get the environment
    var env = buildCouchbaseEnvironment( configData );
    // connect to the cluster
    variables['couchbaseCluster'] = newJava( "com.couchbase.client.java.CouchbaseCluster" ).create(
      env,
      servers
    );
    // connect to the bucket
    var bucket = variables.couchbaseCluster.openBucket(
      javaCast( "string", configData.bucketName ),
      javaCast( "string", configData.password )
    );
    return bucket;
  }

  /**
  * Build a couchbase environment
  *
  * @config.hint The CFCouchbase config object
  *
  * @Return The java environment class ( com.couchbase.client.java.env.DefaultCouchbaseEnvironment )
  */
  private any function buildCouchbaseEnvironment( required any config ) {
    // get the environment builder
    var builder = newJava( "com.couchbase.client.java.env.DefaultCouchbaseEnvironment" ).builder();
    // build the environment
    builder = builder
      .sslEnabled( javaCast( "boolean", arguments.config.sslEnabled ) )
      .queryEnabled( javaCast( "boolean", arguments.config.queryEnabled ) )
      .queryPort( javaCast( "int", arguments.config.queryPort ) )
      .bootstrapHttpEnabled( javaCast( "boolean", arguments.config.bootstrapHttpEnabled ) )
      .bootstrapHttpDirectPort( javaCast( "int", arguments.config.bootstrapHttpDirectPort ) )
      .bootstrapHttpSslPort( javaCast( "int", arguments.config.bootstrapHttpSslPort ) )
      .bootstrapCarrierEnabled( javaCast( "boolean", arguments.config.bootstrapCarrierEnabled ) )
      .bootstrapCarrierDirectPort( javaCast( "int", arguments.config.bootstrapCarrierDirectPort ) )
      .bootstrapCarrierSslPort( javaCast( "int", arguments.config.bootstrapCarrierSslPort ) )
      .dnsSrvEnabled( javaCast( "boolean", arguments.config.dnsSrvEnabled ) )
      .mutationTokensEnabled( javaCast( "boolean", arguments.config.mutationTokensEnabled ) )
      .kvTimeout( javaCast( "long", arguments.config.kvTimeout ) )
      .viewTimeout( javaCast( "long", arguments.config.viewTimeout ) )
      .queryTimeout( javaCast( "long", arguments.config.queryTimeout ) )
      .connectTimeout( javaCast( "long", arguments.config.connectTimeout ) )
      .disconnectTimeout( javaCast( "long", arguments.config.disconnectTimeout ) )
      .managementTimeout( javaCast( "long", arguments.config.managementTimeout ) )
      .maxRequestLifetime( javaCast( "long", arguments.config.maxRequestLifetime ) )
      .keepAliveInterval( javaCast( "long", arguments.config.keepAliveInterval ) )
      .kvEndpoints( javaCast( "int", arguments.config.kvEndpoints ) )
      .viewEndpoints( javaCast( "int", arguments.config.viewEndpoints ) )
      .queryEndpoints( javaCast( "int", arguments.config.queryEndpoints ) )
      .tcpNodelayEnabled( javaCast( "boolean", arguments.config.tcpNodelayEnabled ) )
      .requestBufferSize( javaCast( "int", arguments.config.requestBufferSize ) )
      .responseBufferSize( javaCast( "int", arguments.config.responseBufferSize ) )
      .dcpEnabled( javaCast( "boolean", arguments.config.dcpEnabled ) )
      .bufferPoolingEnabled( javaCast( "boolean", arguments.config.bufferPoolingEnabled ) );
    if( len( arguments.config.sslKeystoreFile ) ) {
      builder = builder.sslKeystoreFile( javaCast( "string", arguments.config.sslKeystoreFile ) );
    }
    if( len( arguments.config.sslKeystorePassword ) ) {
      builder = builder.sslKeystorePassword( javaCast( "string", arguments.config.sslKeystorePassword ) );
    }
    if( isObject( arguments.config.reconnectDelay ) ) {
      builder = builder.reconnectDelay( arguments.config.reconnectDelay );
    }
    if( isObject( arguments.config.retryDelay ) ) {
      builder = builder.retryDelay( arguments.config.retryDelay );
    }
    if( isObject( arguments.config.retryStrategy ) ) {
      builder = builder.retryStrategy( arguments.config.retryStrategy );
    }
    if( isObject( arguments.config.observeIntervalDelay ) ) {
      builder = builder.observeIntervalDelay( arguments.config.observeIntervalDelay );
    }
    if( arguments.config.ioPoolSize ) {
      builder = builder.ioPoolSize( javaCast( "int", arguments.config.ioPoolSize ) );
    }
    if( arguments.config.computationPoolSize ) {
      builder = builder.computationPoolSize( javaCast( "int", arguments.config.computationPoolSize ) );
    }
    if( isObject( arguments.config.ioPool ) ) {
      builder = builder.ioPool( arguments.config.ioPool );
    }
    if( isObject( arguments.config.scheduler ) ) {
      builder = builder.scheduler( arguments.config.scheduler );
    }
    if( len( arguments.config.userAgent ) ) {
      builder = builder.userAgent( javaCast( "string", arguments.config.userAgent ) );
    }
    if( len( arguments.config.packageNameAndVersion ) ) {
      builder = builder.packageNameAndVersion( javaCast( "string", arguments.config.packageNameAndVersion ) );
    }
    if( isObject( arguments.config.eventBus ) ) {
      builder = builder.eventBus( arguments.config.eventBus );
    }
    if( isObject( arguments.config.runtimeMetricsCollectorConfig ) ) {
      builder = builder.runtimeMetricsCollectorConfig( arguments.config.runtimeMetricsCollectorConfig );
    }
    if( isObject( arguments.config.networkLatencyMetricsCollectorConfig ) ) {
      builder = builder.networkLatencyMetricsCollectorConfig( arguments.config.networkLatencyMetricsCollectorConfig );
    }
    if( isObject( arguments.config.defaultMetricsLoggingConsumer ) ) {
      builder = builder.defaultMetricsLoggingConsumer( arguments.config.defaultMetricsLoggingConsumer );
    }
    return builder.build();
  }

  /**
  * Standardize and validate configuration object
  *
  * @config.hint The config options as a struct, path or instance.
  *
  * @Return The CFCouchbase config CFC
  */
  private any function validateConfig( required any config  ) {
    // do we have a simple path to inflate
    if( isSimpleValue( arguments.config ) ) {
      // build out cfc
      arguments.config = new "#arguments.config#"();
    }

    // We've been given a CFC instance
    if( isObject( arguments.config ) ) {

      // Validate the configure() method
      if( !structKeyExists( arguments.config, "configure" ) ) {
        throw(
          message="Config file must have a configure() method",
          detail="Valid config CFCs must set their config settings into the variables scope in a configure() method.",
          type="InvalidConfig"
        );
      }

      // Configure the CFC
      arguments.config.configure();

      // check family, for memento injection
      if( isInstanceOf( arguments.config, "cfcouchbase.config.CouchbaseConfig" ) ) {
        return arguments.config;
      }
      else  {
        // get memento out via mixin
        var oConfig = new config.CouchbaseConfig();
        arguments.config.getMemento = oConfig.getMemento;
        return oConfig.init( argumentCollection=arguments.config.getMemento() );
      }
    }

    // check if its a struct literal of config options
    if( isStruct( arguments.config ) ) {
      // init config object with memento
      return new config.CouchbaseConfig( argumentCollection=arguments.config );
    }

  }

  /**
  * Get a list of all the jars in the lib directory
  *
  * @Return An array of jar file names
  */
  private array function getLibJars() {
    return directoryList( variables.libPath, false, "path" );
  }

  /**
  * Load JavaLoader with the SDK
  */
  private void function loadSDK() {
    try {

      // verify if not in server scope
      if( !structKeyExists( server, variables.javaLoaderID ) ) {
        lock name="#variables.javaLoaderID#" throwOnTimeout="true" timeout="15" type="exclusive" {
          if( !structKeyExists( server, variables.javaLoaderID ) ) {
            // Create and load
            server[variables.javaLoaderID] = new util.javaloader.JavaLoader( loadPaths=getLibJars() );
          }
        }
      } // end if static server check

    }
    catch( any e ) {
      e.printStackTrace();
      throw(
        message="Error Loading Couchbase Client Jars: " & e.message & " " & e.detail,
        detail=e.stacktrace
      );
    }
  }

  /**
  * Default persist and replicate from arguments.  Will create "persistTo" with a default value of ZERO and "replicateTo" with a
  * default value of ZERO if they don't exist.  Also translates from string inputs to the Java enum value
  * @args.hint The argument collection to process
  * @Return The argument collection with the defaulted values.
  */
  private any function defaultPersistReplicate( required struct args )  {
    var validPersistTo = "NONE,MASTER,ONE,TWO,THREE,FOUR";
    var validReplicateTo = "NONE,ONE,TWO,THREE";
    // persistTo
    if( structKeyExists( args, "persistTo" ) ) {
      args['persistTo'] = trim( args.persistTo );
      // if the value is ZERO set it to NONE for backwards compatibility
      if( args.persistTo == "ZERO" ) {
        args['persistTo'] = "NONE";
      }
      if( !listFindNoCase( validPersistTo, args.persistTo ) ) {
        throw(
          message="Invalid persistTo value of [" & args.persistTo & "]",
          detail="Valid values are [" & validPersistTo & "]",
          type="InvalidPersistTo"
        );
      }
      args['persistTo'] = this.persistTo[args.persistTo];
    } else  {
      // Default it
      args['persistTo'] = this.persistTo.NONE;
    }
    // replicateTo
    if( structKeyExists( args, "replicateTo" ) ) {
      args['replicateTo'] = trim( args.replicateTo );
      // if the value is ZERO set it to NONE for backwards compatibility
      if( args.replicateTo == "ZERO" ) {
        args['replicateTo'] = "NONE";
      }
      if( !listFindNoCase( validReplicateTo, args.replicateTo ) ) {
        throw(
          message="Invalid replicateTo value of [" & args.replicateTo & "]",
          detail="Valid values are [" & validReplicateTo & "]",
          type="InvalidReplicateTo"
        );
      }
      args['replicateTo'] = this.replicateTo[args.replicateTo];
    } else  {
      // Default it
      args['replicateTo'] = this.replicateTo.NONE;
    }
    return args;
  }

  /**
  * Default timeout in arguments.  Will create "timeout" with a default value specified in settings
  * Also accounts for timeouts over 30 days which must be represented as epoch date.
  *
  * @args.hint The argument collection to process
  *
  * @Return The argument collection with the defaulted values.
  */
  private any function defaultTimeout( required args ) {
    var secondsIn30Days = 30 * 24 * 60 * 60;

    args['timeout'] = !structKeyExists( args, "timeout" ) ? variables.couchbaseConfig.getDefaultTimeout() : args.timeout;

    // Validate timeout
    if( !isNumeric( args.timeout ) || args.timeout < 0 ) {
      throw(
        message="Invalid timeout value of [" & args.timeout & "]",
        detail="Valid values are positive integers",
        type="InvalidTimeout"
      );
    }

    // Convert minutes to seconds
    args['timeout'] = args.timeout * 60;

    // Timeouts over 30 days must be treated as epoch dates ( seconds since 1970 )
    // If the times are greater than 30 days, add seconds since epoch to them so they become a full epoch date.
    if( args.timeout > secondsIn30Days ) {
      var secondsSinceEpoch = datediff( "s", createdatetime( 1970, 1, 1, 0, 0, 0 ), dateConvert( "local2Utc", now() ) );
      args['timeout'] += secondsSinceEpoch;
    }

    return args;
  }

  /**
  * Gets the utility helper
  *
  * @Return Return the utility helper
  */
  public any function getUtility() {
    return variables.util;
  }

}