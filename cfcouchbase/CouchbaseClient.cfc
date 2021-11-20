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
    variables['version'] = "@build.version@+@build.number@";
    variables['SDKVersion'] = "3.1.6"; // https://docs.couchbase.com/sdk-api/couchbase-java-client-3.1.6/index.html
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

    // Java static class references
    this.ReplicateTo = newJava( "com.couchbase.client.java.kv.ReplicateTo" );
    this.PersistTo = newJava( "com.couchbase.client.java.kv.PersistTo" );
    this.LookupInSpec = newJava( 'com.couchbase.client.java.kv.LookupInSpec' );
    this.MutateInSpec = newJava( 'com.couchbase.client.java.kv.MutateInSpec' );

    variables.Optional = newJava( "java.util.Optional" );
    variables.Paths = newJava( "java.nio.file.Paths" );
    variables.Duration = newJava( "java.time.Duration" );
    variables.RawJsonTranscoder = newJava( "com.couchbase.client.java.codec.RawJsonTranscoder" );
    variables.RawBinaryTranscoder = newJava( "com.couchbase.client.java.codec.RawBinaryTranscoder" );
    variables.RawStringTranscoder = newJava( "com.couchbase.client.java.codec.RawStringTranscoder" );
    variables.DesignDocumentNamespace = newJava( "com.couchbase.client.java.view.DesignDocumentNamespace" );
    variables.ExportFormat = newJava( 'com.couchbase.client.core.cnc.Context$ExportFormat' );

    variables.StringClass = newJava( "java.lang.String" ).getClass();
    variables.ObjectClass = newJava( 'java.lang.Object' ).getClass();
    variables.ByteArrayClass = javaCast( 'byte[]', [] ).getClass();


    variables.PublishDesignDocumentOptions = newJava( "com.couchbase.client.java.manager.view.PublishDesignDocumentOptions" );
    variables.ViewOptions = newJava( "com.couchbase.client.java.view.ViewOptions" );
    variables.QueryOptions = newJava( "com.couchbase.client.java.query.QueryOptions" );
    variables.UpsertOptions = newJava( "com.couchbase.client.java.kv.UpsertOptions" );
    variables.IncrementOptions = newJava( "com.couchbase.client.java.kv.IncrementOptions" );
    variables.DecrementOptions = newJava( "com.couchbase.client.java.kv.DecrementOptions" );
    variables.GetOptions = newJava( "com.couchbase.client.java.kv.GetOptions" );
    variables.ReplaceOptions = newJava( "com.couchbase.client.java.kv.ReplaceOptions" );
    variables.GetAndTouchOptions = newJava( "com.couchbase.client.java.kv.GetAndTouchOptions" );
    variables.GetAndLockOptions = newJava( "com.couchbase.client.java.kv.GetAndLockOptions" );
    variables.InsertOptions = newJava( "com.couchbase.client.java.kv.InsertOptions" );
    variables.RemoveOptions = newJava( "com.couchbase.client.java.kv.RemoveOptions" );
    variables.AppendOptions = newJava( "com.couchbase.client.java.kv.AppendOptions" );
    variables.PrependOptions = newJava( "com.couchbase.client.java.kv.PrependOptions" );
    variables.TouchOptions = newJava( "com.couchbase.client.java.kv.TouchOptions" );
    variables.GetAnyReplicaOptions = newJava( "com.couchbase.client.java.kv.GetAnyReplicaOptions" );
    variables.GetAllReplicasOptions = newJava( "com.couchbase.client.java.kv.GetAllReplicasOptions" );
    variables.MutateInOptions = newJava( "com.couchbase.client.java.kv.MutateInOptions" );
    

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
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, ACTIVE, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ NONE, ONE, TWO, THREE ]
  * @return A structure containing the id, cas, expiry and hashCode document metadata values
  */
  public any function upsert(
    required string id,
    required any value,
    numeric timeout,
    string persistTo,
    string replicateTo
  ) {
    var options = UpsertOptions.upsertOptions()
    // default timeout
    defaultTimeout( arguments, options );
    // default persist and replicate
    defaultPersistReplicate( arguments, options );
    
    arguments.value = setTranscoder( arguments.value, options ).value;

    // write the document
    var result = variables.couchbaseBucket.defaultCollection().upsert(
      variables.util.normalizeID( arguments.id ),
      arguments.value,
      options
    );
    return {
      'id' = variables.util.normalizeID( arguments.id ),
      'cas' = result.cas(),
      'expiry' = 0,
      'mutationToken' = result.mutationToken().get(),
      // hash code errors for binary documents
      'hashCode' = !isBinary(arguments.value) ? result.hashCode() : 0
    };
  }

  /**
  * Sets the transcoder into an options object based on the data type
  * @return 
  */
  public any function setTranscoder(
    any value="",
    required options,
    string dataType=""
  ) {
    var result = {
      value = value,
      class = stringClass
    };
    // if the data type was pass just use it, otherwise infer it
    arguments['dataType'] = len( arguments.dataType ) ? arguments.dataType : variables.util.getDataType( arguments.value );
    switch( arguments.dataType ) {
      case "struct":
      case "array":
        options.transcoder( variables.RawJsonTranscoder.INSTANCE );
        result.value = serializeData( arguments.value );
        break;
      case "double":
      case "long":
      case "boolean":
        options.transcoder( variables.RawJsonTranscoder.INSTANCE );
        result.value = toString( value );
        break;
      case "binary":
        options.transcoder( variables.RawBinaryTranscoder.INSTANCE );
        result.class = ByteArrayClass;
        break;
      case "string":
        options.transcoder( variables.RawStringTranscoder.INSTANCE );
        result.value = toString( value );
        break;
      default: // the data type could be determined, just serialize the data
        options.transcoder( variables.RawStringTranscoder.INSTANCE );
        result.value = serializeData( arguments.value );
    }
    return result;
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
  public any function newEmptyDocument_removed(
    string dataType="unknown",
    any value=""
  ) {
    var document = "";
    // if the data type was pass just use it, otherwise infer it
    arguments['dataType'] = len( arguments.dataType ) ? arguments.dataType : variables.util.getDataType( arguments.value );
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
        document = newJava( "com.couchbase.client.java.document.BinaryDocument" );
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
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, ACTIVE, ONE, TWO, THREE, FOUR ]
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
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, ACTIVE, ONE, TWO, THREE, FOUR ]
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
    var options = ReplaceOptions.replaceOptions()
    // default timeout
    defaultTimeout( arguments, options );
    // default persist and replicate
    defaultPersistReplicate( arguments, options );
    
    arguments.value = setTranscoder( arguments.value, options ).value;

    var result = {
      'status' = true,
      'detail' = "SUCCESS",
      'cas' = 0
    };

    try {
      options.cas( arguments.cas );
      var mutationResult = variables.couchbaseBucket.defaultCollection().replace(
        variables.util.normalizeID( arguments.id ),
        arguments.value,
        options
      );
      result['cas'] = mutationResult.cas();
    }
    catch( any e ) {
      switch( e.type ) {
        // the cas value is invalid
        case "com.couchbase.client.core.error.CasMismatchException":
          result['status'] = false;
          result['detail'] = "CAS_CHANGED";
        break;
        // the document was not found
        case "com.couchbase.client.core.error.DocumentNotFoundException":
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
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, ACTIVE, ONE, TWO, THREE, FOUR ]
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
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, ACTIVE, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  * @legacy.hint Whether or not we are dealing with a new sdk 2.x+ method set legacy to false, under the hood legacy methods call this and the value
  *
  * @return A boolean indicating whether or not the insert was successful
  */
  public boolean function insert(
    required string id,
    required any value,
    numeric timeout,
    string persistTo,
    string replicateTo,
    boolean legacy=false
  ) {
    var options = InsertOptions.insertOptions()
   
    // default timeout
    defaultTimeout( arguments, options );
    // default persist and replicate
    defaultPersistReplicate( arguments, options );
    
    arguments.value = setTranscoder( arguments.value, options ).value;

    try {
      // write the document
      var result = variables.couchbaseBucket.defaultCollection().insert(
        variables.util.normalizeID( arguments.id ),
        arguments.value,
        options
      );
    } catch( any e ) {
      // the document already exists and cannot be inserted
      if( e.type == "com.couchbase.client.core.error.DocumentExistsException" ) {
        return false;
      }
      rethrow;
    }
    return true;
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
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, ACTIVE, ONE, TWO, THREE, FOUR ]
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
  * Upsert multiple documents with a single operation.  Pass in a struct of documents to set where the IDs of the struct are the document IDs.
  * The values in the struct are the values being set.  All documents share the same timout, persistTo, and replicateTo settings.
  *
  * <pre class='brush: cf'>
  * people = {
  * &nbsp;&nbsp;brad = { name: "Brad", age: 33, hair: "red" },
  * &nbsp;&nbsp;luis = { name: "Luis", age: 35, hair: "black" },
  * &nbsp;&nbsp;bill = { name: "Bill", age: 21, hair: "blond" }
  * };
  * client.upsertMulti( people );
  * </pre>
  *
  * @data.hint A struct ( key/value pair ) of documents to set into Couchbase.
  * @timeout.hint The expiration of the documents in minutes.
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, ACTIVE, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  *
  * @return A structure containing the id, cas, expiry and hashCode document metadata values for each upserted document
  */
  public any function upsertMulti(
    required struct data,
    numeric timeout,
    string persistTo,
    string replicateTo
  ) {
    var results = {};
    // Loop over incoming key/value pairs
    for( var id in arguments.data ) {
      // save the result
      results[id] = this.upsert(
        id=id,
        value=arguments.data[id],
        timeout=arguments.timeout?:javaCast('null',''),
        persistTo=arguments.persistTo?:javaCast('null',''),
        replicateTo=arguments.replicateTo?:javaCast('null','')
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
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, ACTIVE, ONE, TWO, THREE, FOUR ]
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
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, ACTIVE, ONE, TWO, THREE, FOUR ]
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
    return replaceWithCAS( argumentCollection=arguments ).status;    
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
    string dataType="json"
  ) {
    // These are the same API call
    var result = getWithCAS( argumentCollection=arguments );
    if( !isNull( result ) ) {
      return result.value;
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
    any inflateTo="",
    string dataType="json"
  ) {
    if( !len( arguments.id ) ) {
      return;
    }

    var options = GetOptions.getOptions();
    var transcoderResult = setTranscoder( options=options, dataType=dataType );
    
    try {
      var result = variables.couchbaseBucket.defaultCollection().get(
        variables.util.normalizeID( arguments.id ),
        options
      );
    } catch( any e ) {
      // basically an attempt was made to retrieve a legacy document that cannot be inflated
      // to the new Json*Document objects provided by the SDK.  try to get the document as a
      // legacy document
      if( e.type == "com.couchbase.client.core.error.DocumentNotFoundException" ) {
        return;
      }
      rethrow;
    }

    return {
      'expiry' = result.expiry().isEmpty() ? "" : result.expiry().get(),
      'cas' = result.cas(),
      'value' = deserializeData(
        arguments.id,
        result.contentAs( transcoderResult.class ),
        arguments.inflateTo,
        arguments.deserialize,
        arguments.deserializeOptions
      )
    };
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
    any inflateTo="",
    string dataType="json"
  ) {
  	var options = GetAndTouchOptions.getAndTouchOptions();
    
    var thisExpiryDuration = '';
    var fakeOptions = {
      expiry : (e)=>{thisExpiryDuration=e}
    };
    defaultTimeout( arguments, fakeOptions );
    
    var transcoderResult = setTranscoder( options=options, dataType=dataType );

    arguments.id = variables.util.normalizeID( arguments.id );
    
    try {
      var result = variables.couchbaseBucket.defaultCollection().getAndTouch(
        arguments.id,
        thisExpiryDuration,
        options
      );
    }
    catch( any e ) {
      if( e.type == "com.couchbase.client.core.error.DocumentNotFoundException" ) {
        return;
      }
      rethrow;
    }

    return {
      'expiry' = result.expiryTime().isEmpty() ? "" : result.expiryTime().get().getEpochSecond(),
      'cas' = result.cas(),
      'value' = deserializeData(
        arguments.id,
        result.contentAs( transcoderResult.class ),
        arguments.inflateTo,
        arguments.deserialize,
        arguments.deserializeOptions
      )
    };

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
    any inflateTo="",
    string dataType="json"
  ) {
    if( arguments.lockTime > 30 ) {
      throw(
        message="Invalid lockTime",
        detail="The lockTime value cannot exceed 30 seconds",
        type="CouchbaseClient.GetAndLockTimeException"
      );
    }


    var options = GetAndLockOptions.getAndLockOptions();
    var transcoderResult = setTranscoder( options=options, dataType=dataType );
    
    try {
      var result = variables.couchbaseBucket.defaultCollection().getAndLock(
        variables.util.normalizeID( arguments.id ),
        Duration.ofSeconds( arguments.lockTime ),
        options
      );
    } catch( any e ) {
      // basically an attempt was made to retrieve a legacy document that cannot be inflated
      // to the new Json*Document objects provided by the SDK.  try to get the document as a
      // legacy document
      if( e.type == "com.couchbase.client.core.error.DocumentNotFoundException" ) {
        return;
      }
      rethrow;
    }

    return {
      'expiry' = result.expiryTime().isEmpty() ? "" : result.expiryTime().get().getEpochSecond(),
      'cas' = result.cas(),
      'value' = deserializeData(
        arguments.id,
        result.contentAs( transcoderResult.class ),
        arguments.inflateTo,
        arguments.deserialize,
        arguments.deserializeOptions
      )
    };

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
    variables.couchbaseBucket.defaultCollection().unlock(
      variables.util.normalizeID( arguments.id ),
      javaCast( "long", arguments.cas )
    );
    return true;
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
  * @return A struct the same as from get() but with a isReplica key.
  */
  public struct function getFromReplica(
    required string id,
    boolean deserialize=true,
    struct deserializeOptions={},
    any inflateTo="",
    string dataType="json"
  ) {
    var options = GetAnyReplicaOptions.GetAnyReplicaOptions();
    var transcoderResult = setTranscoder( options=options, dataType=dataType );
    
    try {
      var result = variables.couchbaseBucket.defaultCollection().getAnyReplica(
        variables.util.normalizeID( arguments.id ),
        options
      );
    } catch( any e ) {
      if( e.type == "com.couchbase.client.core.error.DocumentUnretrievableException" ) {
        return;
      }
      rethrow;
    }

    return {
      'expiry' = result.expiry().isEmpty() ? "" : result.expiry().get(),
      'cas' = result.cas(),
      'isReplica' = result.isReplica(),
      'value' = deserializeData(
        arguments.id,
        result.contentAs( transcoderResult.class ),
        arguments.inflateTo,
        arguments.deserialize,
        arguments.deserializeOptions
      )
    };
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
  * @return An aray of documents from all replicas
  */
  public array function getFromAllReplicas(
    required string id,
    boolean deserialize=true,
    struct deserializeOptions={},
    any inflateTo="",
    string dataType="json"
  ) {
    var options = GetAllReplicasOptions.GetAllReplicasOptions();
    var transcoderResult = setTranscoder( options=options, dataType=dataType );
    
    var result = variables.couchbaseBucket.defaultCollection().getAllReplicas(
      variables.util.normalizeID( arguments.id ),
      options
    ).toArray();

    return arrayMap( result, function(result){
      return {
        'expiry' = result.expiry().isEmpty() ? "" : result.expiry().get(),
        'cas' = result.cas(),
        'isReplica' = result.isReplica(),
        'value' = deserializeData(
          id,
          result.contentAs( transcoderResult.class ),
          inflateTo,
          deserialize,
          deserializeOptions
        )
      };
    } );
  }

  /**
  * Performs a Sub Doc LookupIn operation that will return only specific attributes from a document instead of the whole document
  *
  * <pre class='brush: cf'>
  * lookup = client.lookupIn( 'user_aaronb' )
  *                   .get( 'address' )
  *                   .get( 'phones[0]' )
  *                   .exists( 'dob' )
  *                   .execute();
  *  address = lookup.content( 'address' );
  *  phone = lookup.content( 'phones[0]' );
  * </pre>
  *
  * @id.hint The ID of the document to retrieve.
  *
  * @return A Lookup builder
  */
  public any function lookupIn( required string id ) {
    return new subdoc.LookupInBuilder( id=variables.util.normalizeID( arguments.id ), couchbaseClient=this );
  }

  /**
  * Performs a Subdoc MutateIn operation that modify
  *
  * <pre class='brush: cf'>
  * mutate = client.mutateIn( 'user_aaronb' )
  *                   .upsert( 'username', 'abenton' )
  *                   .upsert( 'email', 'ab723893@gmail.com' )
  *                   .execute();
  * </pre>
  *
  * @id.hint The ID of the document to retrieve.
  *
  * @return A Lookup builder
  */
  public any function mutateIn( required string id ) {
  //  MutateInSpec
    return new subdoc.MutateInBuilder( id=variables.util.normalizeID( arguments.id ), couchbaseClient=this, mutateInOptions=MutateInOptions.mutateInOptions() );
  }

  /**
  * Shutdown the native client connection
  *
  * <pre class='brush: cf'>
  * client.shutdown( 10 );
  * </pre>
  *
  * @timeout.hint The timeout in seconds
  *
  * @return A refernce to "this" CFC
  */
  public CouchbaseClient function shutdown( numeric timeout=10 ) {
    // There is a nasty error if you try to shutdown a client twice, so only do it if it has at least one endpoint defined.
    if( structCount( variables.couchbaseCluster.diagnostics().endpoints() ) ) {
      variables.couchbaseCluster.disconnect( Duration.ofSeconds( javaCast( "long", arguments.timeout ) ) );
    }
    return this;
  }

  /**
  * Flush all caches from all servers with a delay of application.
  *
  * <pre class='brush: cf'>
  * client.flush( 'default' );
  * </pre>
  *
  * @bucketName.hint Name of bucket to flush.  Defaults to bucket set in config.
  *
  * @return A Java future object. ( net.spy.memcached.internal.OperationFuture )
  */
  public any function flush( string bucketName=variables.couchbaseConfig.getBucketName() ) {
    return variables.couchbaseCluster.buckets().flushBucket( bucketName );
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
  public function getStats() {
    variables.couchbaseCluster.waitUntilReady( Duration.ofMillis( 10000 ) );
    return deserializeJSON(
      variables.couchbaseCluster.diagnostics().exportToJson()
    );
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
  * @value.hint The amount to increment or decrement by
  * @defaultValue.hint The default value ( if the counter does not exist, this defaults to 0 );
  * @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
  *
  * @return The new value
  */
  public any function counter(
    required string id,
    required numeric value,
    numeric defaultValue=0,
    numeric timeout
  ) {

    var options = value > 0 ? IncrementOptions.incrementOptions() : DecrementOptions.decrementOptions();

    // default timeouts
    defaultTimeout( arguments, options );

    options.initial( javacast( "long", defaultValue ) );
    options.delta( javacast( "long", abs( value ) ) );
    
    var binaryCollection = variables.couchbaseBucket.defaultCollection().binary();

    // increment
    if( value > 0 ) {
      var document = binaryCollection.increment(
        variables.util.normalizeID( arguments.id ),
        options
      );
    // decrement
    } else {
      var document = binaryCollection.decrement(
        variables.util.normalizeID( arguments.id ),
        options
      );
    }
    
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
    var options = touchOptions.TouchOptions();
    
    var thisExpiryDuration = '';
    var fakeOptions = {
      expiry : (e)=>{thisExpiryDuration=e}
    };
    defaultTimeout( arguments, fakeOptions );
    
    var MutationResult = variables.couchbaseBucket.defaultCollection().touch(
        javaCast( "string", variables.util.normalizeID( arguments.id ) ),
        thisExpiryDuration,
        options
    );
    return true;
  }

  /**
  * Delete a value with durability options. The durability options here operate similarly to those documented in the set method.
  *
  * <pre class='brush: cf'>
  * client.remove( 'brad' );
  * </pre>
  *
  * @id The ID of the document to delete, or an array of ID's to delete
  * @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, ACTIVE, ONE, TWO, THREE, FOUR ]
  * @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
  *
  * @return A structure of document IDs w/ boolean values or just a boolean whether or not the delete was successful
  */
  public any function remove(
    required any id,
    string persistTo,
    string replicateTo
  ) {
    var options = RemoveOptions.removeOptions();

    arguments['id'] = variables.util.normalizeID( arguments.id );

    // default persist and replicate
    defaultPersistReplicate( arguments, options );

    // simple or array
    arguments['id'] = isSimpleValue( arguments.id ) ? listToArray( arguments.id ) : arguments.id;

    var results = {};
    // iterate over the results
    for( var document_id in arguments.id ) {
      try {
        variables.couchbaseBucket.defaultCollection().remove(
          document_id,
          options
        );
        // the operation returns the document that was deleted if we got here it was successful
        results[document_id] = true;
      }
      catch( any e ) {
        // if the document doesn't exist or the durability options couldn't be met set a false value for the key
        if( e.type == "com.couchbase.client.core.error.DocumentNotFoundException" ) {
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
    return variables.couchbaseBucket.defaultCollection().exists( variables.util.normalizeID( arguments.id ) ).exists();
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
  *
  * @return An array containing an item for each server in the cluster.  Servers are represented as a string containing their address produced via java.net.InetSocketAddress.toString()
  */
  public array function getAvailableServers() {
    var stats = getStats();
    var servers = [];
    for( var node in stats.services.kv ?: [] ) {
      var host = listFirst( node.remote ?: '', ':' );
      if( ( node.state ?: '' ) == "connected" && !servers.findNoCase( host ) ) {
        arrayAppend( servers, host );
      }
    }
    for( var node in stats.services.query ?: [] ) {
      var host = listFirst( node.remote ?: '', ':' );
      if( ( node.state ?: '' ) == "connected" && !servers.findNoCase( host ) ) {
        arrayAppend( servers, host );
      }
    }
    for( var node in stats.services.search ?: [] ) {
      var host = listFirst( node.remote ?: '', ':' );
      if( ( node.state ?: '' ) == "connected" && !servers.findNoCase( host ) ) {
        arrayAppend( servers, host );
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
  public array function getUnAvailableServers() {
    var stats = getStats();
    var servers = [];
    for( var node in stats.services.kv ?: [] ) {
      var host = listFirst( node.remote ?: '', ':' );
      if( ( node.state ?: '' ) != "connected" && !servers.findNoCase( host ) ) {
        arrayAppend( servers, host );
      }
    }
    for( var node in stats.services.query ?: [] ) {
      var host = listFirst( node.remote ?: '', ':' );
      if( ( node.state ?: '' ) != "connected" && !servers.findNoCase( host ) ) {
        arrayAppend( servers, host );
      }
    }
    for( var node in stats.services.search ?: [] ) {
      var host = listFirst( node.remote ?: '', ':' );
      if( ( node.state ?: '' ) != "connected" && !servers.findNoCase( host ) ) {
        arrayAppend( servers, host );
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
    return deserializeJSON( variables.couchbaseBucket.environment().exportAsString( ExportFormat.JSON ) );
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
    var options = AppendOptions.appendOptions();
    // default persist and replicate
    defaultPersistReplicate( arguments, options );

    if( !isNull( arguments.cas ) ) {
      options.cas( arguments.cas );
    }

    // append the document
    variables.couchbaseBucket.defaultCollection().binary().append(
      variables.util.normalizeID( arguments.id ),
      value.getBytes(),
      options
    );
    return get( id );
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
    var options = PrependOptions.prependOptions();
    // default persist and replicate
    defaultPersistReplicate( arguments, options );

    if( !isNull( arguments.cas ) ) {
      options.cas( arguments.cas );
    }

    // append the document
    variables.couchbaseBucket.defaultCollection().binary().prepend(
      variables.util.normalizeID( arguments.id ),
      value.getBytes(),
      options
    );
    return get( id );
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
  public any function newViewQueryOptions(
    struct options= {}
  ) {
    var ViewOptions = ViewOptions.viewOptions();
    arguments['options'] = variables.queryHelper.processOptions( arguments.options );

    ViewOptions.namespace( getDesignDocumentNamespace( structKeyExists( arguments.options, "development" ) ) );

    // set debug
    if( structKeyExists( arguments.options, "debug" ) ) {
      ViewOptions.debug( javaCast( "boolean", arguments.options.debug ) );
    }
    // set descending
    if( structKeyExists( arguments.options, "descending" ) && arguments.options.descending ) {
      ViewOptions.order( newJava( 'com.couchbase.client.java.view.ViewOrdering' ).valueOf( 'DESCENDING' ) );
    } else {
      ViewOptions.order( newJava( 'com.couchbase.client.java.view.ViewOrdering' ).valueOf( 'ASCENDING' ) );
    }
    // set the endKey
    if( structKeyExists( arguments.options, "endKey" ) ) {
      ViewOptions.endKey( arguments.options.endKey );
    }
    // set the endKeyDocId
    if( structKeyExists( arguments.options, "endKeyDocId" ) ) {
      ViewOptions.endKeyDocId( arguments.options.endKeyDocId );
    }
    // set the group
    if( structKeyExists( arguments.options, "group" ) ) {
      ViewOptions.group( arguments.options.group );
    }
    // set the groupLevel
    if( structKeyExists( arguments.options, "groupLevel" ) ) {
      ViewOptions.groupLevel( arguments.options.groupLevel );
    }
    /*
    This is removed from the SDK in 3.x.  You must now manually reterive the doc.
    // set includeDocs
    if( structKeyExists( arguments.options, "includeDocs" ) ) {
      ViewOptions.includeDocs( javaCast( "boolean", arguments.options.includeDocs ) );
    }
    */
    // set inclusiveEnd
    if( structKeyExists( arguments.options, "inclusiveEnd" ) ) {
      ViewOptions.inclusiveEnd( arguments.options.inclusiveEnd );
    }
    // set the key
    if( structKeyExists( arguments.options, "key" ) ) {
      ViewOptions.key( arguments.options.key );
    }
    // set the keys
    if( structKeyExists( arguments.options, "keys" ) ) {
      ViewOptions.keys( arguments.options.keys );
    }
    // set the limit
    if( structKeyExists( arguments.options, "limit" ) ) {
      ViewOptions.limit( arguments.options.limit );
    }
    // set reduce
    if( structKeyExists( arguments.options, "reduce" ) ) {
      ViewOptions.reduce( arguments.options.reduce );
    }
    // set skip
    if( structKeyExists( arguments.options, "skip" ) ) {
      ViewOptions.skip( arguments.options.skip );
    }
    // set stale
    if( structKeyExists( arguments.options, "stale" ) ) {
      ViewOptions.scanConsistency( arguments.options.stale );
    }
    // set startKey
    if( structKeyExists( arguments.options, "startKey" ) ) {
      ViewOptions.startKey( arguments.options.startKey );
    }
    // set startKeyDocId
    if( structKeyExists( arguments.options, "startKeyDocId" ) ) {
      ViewOptions.startKeyDocId( arguments.options.startKeyDocId );
    }
    return ViewOptions;
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
    var ViewQueryOptions = newViewQueryOptions( arguments.options );
    
    var results = variables.couchbaseBucket.viewQuery( arguments.designDocumentName, arguments.viewName, ViewQueryOptions );

    // Native return type?
    if( arguments.returnType == "native" ) {
      return results;
    }

    // iterate and build it out with or without desrializations
    var cfresults = [];
    for( var row in results.rows() ) {
      var IDOpt = row.id();
      // Keys don't have to be a string, they can come back as an array.
      var keyOpt = row.keyAs( ByteArrayClass );
      var valueOpt = row.valueAs( StringClass );


      /**
      * ID: The id of the document in Couchbase, but only available if the query is NOT reduced
      * Document: Only available if the query is NOT reduced
      * Key: This is always available, but null if the query has been reduced, If un-reduced it is the first value passed into emit()
      * Value: This is always available. If reduced, this is the value returned by the reduce(), if not reduced it is the second value passed into emit()
      **/
      var document = {
        'id' = "",
        'document' = "",
        'key' = "",
        'value' = ""
      };
      // Add value if not null
      if( !valueOpt.isEmpty() ) {
        document['value'] = deserializeData(
          "",
          valueOpt.get(),
          arguments.inflateTo,
          arguments.deserialize,
          arguments.deserializeOptions
        );
      }

      // Add key if not null
      if( !keyOpt.isEmpty() ) {
        document['key'] = toString( keyOpt.get() );
      }

      // ID is wrapped in an Optional
      if( !IDOpt.isEmpty() ) {
        document['id'] = IDOpt.get();
      }
      // Did we get a document or none?
      if( !IDOpt.isEmpty() && structKeyExists( arguments.options, "includeDocs" ) && arguments.options.includeDocs ) {
        document['document'] = deserializeData(
          document.id,
          this.get( document.id, deserialize ),
          arguments.inflateTo,
          arguments.deserialize,
          arguments.deserializeOptions
        );
      }

      // Do we have a transformer?
      if( structKeyExists( arguments, "transform" ) && isClosure( arguments.transform ) ) {
        var refLocal = arguments.transform( document );
        // If a value is returned, use it as the document
        if( !isNull( local.refLocal ) ) {
        	document = refLocal;
        }
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
    // TODO: This appears removed in 3.x
    return 0;
   // return variables.couchbaseBucket.invalidateQueryCache();
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
    return views[ arguments.viewName ];
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
    string returnType="struct",
    boolean throwOnException=variables.couchbaseConfig.getQueryThrowOnException()
  ) {
    // build the query
    var n1qlQueryOptions = newN1qlQueryOptions( argumentCollection=arguments );

    // build the output
    var cfresults = {
      'requestId' = '',
      'clientContextId' = '',
      'errors' = [],
      'warnings' = [],
      'metrics' = {},
      'results' = []
    };

    // run the query
    try {
      var QueryResult = variables.couchbaseCluster.query( statement, n1qlQueryOptions );
    } catch( any e ) {
      // We only care about CouchbaseExceptions
      if( !lCase( e.type ).startsWith( 'com.couchbase' ) ) {        
        rethrow;
      }
      // Lucee and Adobe differ in how to access underlying java exception class
		if( server.keyExists( 'lucee' ) ) {
	        if( e.getClass().getName() != 'lucee.runtime.exp.PageException' ) {
	          retrow;
	        }
			var root = e.getPageException().getCause() ?: e.getPageException().getException();
		} else {
			var root = e.cause ?: e;
  		}

      var type = root.getClass().getName();
      var message = root.getMessage();
      var context = root.context();
      var detail = context.toString();
      var rawJSONContext = context.exportAsString( ExportFormat.JSON_PRETTY );
      var JSONContext = deserializeJSON( rawJSONContext );
      JSONContext.errors = JSONContext.errors ?: []
      var errors = JSONContext.errors;
      var errorCode = '';
      if( errors.len() ) {
        errorCode = JSONContext.errors[1].code;
      }
      
      if( throwOnException ) {
        throw(
          message = message,
          detail = detail,
          type = type,
          errorCode = errorCode,
          extendedInfo = rawJSONContext
        );
      } else {
         cfresults[ 'errors' ] = errors;
         cfresults[ 'success' ] = false;
         return cfresults;
      }
    }

    // Native return type?
    if( arguments.returnType == "native" ) {
      return QueryResult;
    }

    cfresults[ 'requestId' ] = QueryResult.metadata().requestId();
    cfresults[ 'clientContextId' ] = QueryResult.metadata().clientContextId();
    cfresults[ 'warnings' ] = arrayAppend( [], QueryResult.metadata().warnings(), true );
    cfresults[ 'success' ] = arrayLen( cfresults.errors ) == 0;

    if( !QueryResult.metadata().metrics().isEmpty() ){
      var metrics = QueryResult.metadata().metrics().get();
      cfresults.metrics[ 'executionTime' ] = metrics.executionTime().toMillis() & ' ms';
      cfresults.metrics[ 'errorCount' ] = metrics.errorCount();
      cfresults.metrics[ 'resultSize' ] = metrics.resultSize();
      cfresults.metrics[ 'warningCount' ] = metrics.warningCount();
      cfresults.metrics[ 'resultCount' ] = metrics.resultCount();
      cfresults.metrics[ 'sortCount' ] = metrics.sortCount();
      cfresults.metrics[ 'mutationCount' ] = metrics.mutationCount();
      cfresults.metrics[ 'elapsedTime' ] = metrics.elapsedTime().toMillis() & ' ms';
    }

    // if there were errors just return
    if( !cfresults.success ) {
      return cfresults;
    }

    // iterate and build it out with or without desrializations
    for( var row in QueryResult.rowsAsObject() ) {
      var document = deserializeData(
        "",
        row.toString(),
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
  public any function newN1qlQueryOptions(
    required string statement,
    any parameters,
    struct options= {}
  ) {
    var queryOptions = QueryOptions.queryOptions();

    if( structKeyExists( arguments, "parameters" ) ) {
      queryOptions.parameters( variables.queryHelper.processN1qlParameters( arguments.parameters ) );
    }

    variables.queryHelper.processN1qlOptions( queryOptions, arguments.options )

    return queryOptions;
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
  * @return A DesignDocument Java object ( com.couchbase.client.java.manager.view.DesignDocument ).
  */
  public any function getDesignDocument(
    required string designDocumentName,
    boolean development=false
  ) {
    var design_doc = javaCast( "null", 0 );
    try {
      design_doc = variables.couchbaseBucket
          .viewIndexes() 
          .getDesignDocument(
            arguments.designDocumentName,
            getDesignDocumentNamespace( arguments.development ) 
          );
    }
    catch (Any e) {
    	if( e.type != 'com.couchbase.client.core.error.DesignDocumentNotFoundException' ) {
    		rethrow;
    	}
      // if the design document does not exist, return null as this is the previously
      // expected behavior
      design_doc = javaCast( "null", 0 );
    }
    return isNull(design_doc) ? javaCast( "null", 0 ) : design_doc;
  }

  function getDesignDocumentNamespace( required boolean development ) {
    if( arguments.development ) {
      return DesignDocumentNamespace.valueOf( 'DEVELOPMENT' );
    }
    return DesignDocumentNamespace.valueOf( 'PRODUCTION' );
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
    try {
      variables.couchbaseBucket
          .viewIndexes() 
          .dropDesignDocument(
            arguments.designDocumentName,
            getDesignDocumentNamespace( arguments.development ) 
          );
    } catch (any e) {
      if( e.type == 'com.couchbase.client.core.error.DesignDocumentNotFoundException' ) {
        // if the design document does not exist an error is thrown, this is not the previous
        // behavior so consider this a success
        return true;
      }
      rethrow;
    }
    return true;
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
 
    return newJava( "com.couchbase.client.java.manager.view.DesignDocument" ).init(
      arguments.designDocumentName
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
  * @Return 0 if the design document doesn't exist as well as if the design document exists, but there is no view by that name.<br> If the view does exist, it will return the index of the view in the designDocument's view array.`
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
    if( structKeyExists( views, viewName ) ) {
      var view = views[ viewName ];
      if( arguments.keyExists( 'mapFunction' ) ) {
        if( arguments.mapFunction != view.map() ) {
          return 0;
        }
        if( arguments.keyExists( 'reduceFunction' ) ) {
          if( view.reduce().isEmpty() || arguments.reduceFunction != view.reduce().get() ) {
            return 0;
          } 
        }
      }
      return 1;
    }
    // Exhausted the array with no match
    return 0;
  }

  /**
  * Creates a new instance of a viewDesign Java object ( com.couchbase.client.protocol.views.ViewDesign )
  *
  * <pre class='brush: cf'>
  * viewDesign = client.newViewDesign( mapFunction, reduceFunction );
  * </pre>
  *
  * @mapFunction.hint The map function for the view represented as a string
  * @reduceFunction.hint The reduce function for the view represented as a string
  * @viewType.hint The type of view to create values are "default" or "spatial"
  *
  * @Return An instance of the Java class com.couchbase.client.java.manager.view.View
  */
  public any function newViewDesign(
    required string mapFunction,
    string reduceFunction="",
    string viewType="default"
  ) {
    var view = "";
    if( arguments.viewType == "default" ) {
      view = newJava( "com.couchbase.client.java.manager.view.View" ).init(
        arguments.mapFunction,
        arguments.reduceFunction
      );
    }
    else if( arguments.viewType == "spatial" ) {
      view = newJava( "com.couchbase.client.java.manager.view.View" ).init(
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
    var viewDesign = newViewDesign( arguments.mapFunction, arguments.reduceFunction );

    designDocument.putView( viewName, viewDesign );
    // create or update the design document
    variables.couchbaseBucket
        .viewIndexes()
        .upsertDesignDocument(
          designDocument,
          getDesignDocumentNamespace( arguments.development )
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
      catch( any e )  {
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
      designDocument.removeView( arguments.viewName );

      if( !structCount( designDocument.views() ) && arguments.removeIfEmpty ) {
        this.removeDesignDocument( argumentCollection=arguments );
      }
      else {
        // recreate the entire design document with the view removed
        designDocument = newDesignDocument( arguments.designDocumentName, views );
        // create or update the design document
      variables.couchbaseBucket
          .viewIndexes()
          .upsertDesignDocument(
            designDocument,
            getDesignDocumentNamespace( arguments.development )
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
    var options = PublishDesignDocumentOptions.publishDesignDocumentOptions();
    variables.couchbaseBucket
        .viewIndexes()
        .publishDesignDocument(
          arguments.designDocumentName,
          options
        );
    return true;
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
  public any function deserializeData(
    required string id,
    required any data,
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
    if( !len( configData.username ) ) {
      throw( 'Empty usernames are not allowed.' );
    }
    if( !len( configData.password ) ) {
      throw( 'Empty passwords are not allowed.' );
    }
    // connect to the cluster
    variables['couchbaseCluster'] = newJava( "com.couchbase.client.java.Cluster" ).connect(
        javaCast( "string", servers.toList() ),
        javaCast( "string", configData.username ),
        javaCast( "string", configData.password )
    );
    // connect to the bucket
    return variables.couchbaseCluster.bucket( javaCast( "string", configData.bucketName ) );
    
  }

  /**
  * Build a couchbase environment
  * http://docs.couchbase.com/sdk-api/couchbase-java-client-2.3.1/com/couchbase/client/java/env/DefaultCouchbaseEnvironment.html
  *
  * @config.hint The CFCouchbase config object
  *
  * @Return The java environment class ( com.couchbase.client.java.env.DefaultCouchbaseEnvironment )
  */
  private any function buildCouchbaseEnvironment( required any config ) {
    // get the environment builder
    var builder = newJava( "com.couchbase.client.java.env.ClusterEnvironment" ).builder();
    
    
    // ============================ Security Config ============================
    var SecurityConfig = newJava( "com.couchbase.client.core.env.SecurityConfig$Builder" );    
    SecurityConfig.enableTls( javaCast( "boolean", arguments.config.sslEnabled ) )    
    /*
    TODO: This needs to use CertificateAuthenticator instead
    if( len( arguments.config.sslKeystoreFile ) ) {
      SecurityConfig.trustStore(
          Paths.get( javaCast( "string", arguments.config.sslKeystoreFile ) ),
          len( arguments.config.sslKeystorePassword ) ? javaCast( "string", arguments.config.sslKeystorePassword ) : javaCast( "null", "" ),
          Optional.empty()
      );
    }*/
    builder.securityConfig( SecurityConfig )
    // ============================ Security Config ============================

    /*
        TODO: This needs to use SeedNode instead
    
      .bootstrapHttpEnabled( javaCast( "boolean", arguments.config.bootstrapHttpEnabled ) )
      .bootstrapHttpDirectPort( javaCast( "int", arguments.config.bootstrapHttpDirectPort ) )
      .bootstrapHttpSslPort( javaCast( "int", arguments.config.bootstrapHttpSslPort ) )
      .bootstrapCarrierEnabled( javaCast( "boolean", arguments.config.bootstrapCarrierEnabled ) )
      .bootstrapCarrierDirectPort( javaCast( "int", arguments.config.bootstrapCarrierDirectPort ) )
      .bootstrapCarrierSslPort( javaCast( "int", arguments.config.bootstrapCarrierSslPort ) )
    */

    /*
        TODO: This needs to use custom IoEnvironment pools instead
        
      if( arguments.config.ioPoolSize ) {
        builder = builder.ioPoolSize( javaCast( "int", arguments.config.ioPoolSize ) );
      }
      if( isObject( arguments.config.ioPool ) ) {
        builder = builder.ioPool( arguments.config.ioPool );
      }
    
    */
    
    // ============================ IO Config ============================
    var IoConfig = newJava( "com.couchbase.client.core.env.IoConfig$Builder" );    
    IoConfig.enableDnsSrv( javaCast( "boolean", arguments.config.dnsSrvEnabled ) );
    IoConfig.enableMutationTokens( javaCast( "boolean", arguments.config.mutationTokensEnabled ) );
    IoConfig.enableTcpKeepAlives( javaCast( "boolean", arguments.config.tcpNodelayEnabled ) );
    IoConfig.numKvConnections( javaCast( "int", arguments.config.kvEndpoints ) );
    IoConfig.maxHttpConnections( arguments.config.queryEndpoints );      
    builder.ioConfig( IoConfig )
    // ============================ IO Config ============================



    // ============================ Timeout Config ============================
    var TimeoutConfig = newJava( "com.couchbase.client.core.env.TimeoutConfig$Builder" );    
    TimeoutConfig.kvTimeout( Duration.ofMillis( javaCast( "long", arguments.config.kvTimeout ) ) ); 
    TimeoutConfig.viewTimeout( Duration.ofMillis( javaCast( "long", arguments.config.viewTimeout ) ) );
    TimeoutConfig.queryTimeout( Duration.ofMillis( javaCast( "long", arguments.config.queryTimeout ) ) );
    TimeoutConfig.connectTimeout( Duration.ofMillis( javaCast( "long", arguments.config.connectTimeout ) ) );
    TimeoutConfig.disconnectTimeout( Duration.ofMillis( javaCast( "long", arguments.config.disconnectTimeout ) ) );
    TimeoutConfig.managementTimeout( Duration.ofMillis( javaCast( "long", arguments.config.managementTimeout ) ) )  ;

    builder.timeoutConfig( TimeoutConfig )
    // ============================ Timeout Config ============================


    // ============================ Top level Config ============================
    
      if( isObject( arguments.config.retryStrategy ) ) {
        builder.retryStrategy( newJava( arguments.config.retryStrategy ) );
      }
      if( isObject( arguments.config.scheduler ) ) {
        builder.scheduler( newJava( arguments.config.scheduler ) );
      }
    // ============================ Top level Config ============================

    // Removed Configs in Java SDK 3.x
    // config.retryDelay
    // config.reconnectDelay
    // config.observeIntervalDelay
    // config.packageNameAndVersion
    // config.userAgent
    // config.viewEndpoints
    // config.socketConnectTimeout
    // config.computationPoolSize
    // config.requestBufferSize
    // config.responseBufferSize
    // config.maxRequestLifetime
    // config.keepAliveInterval
    // config.bufferPoolingEnabled
    // config.callbacksOnIoPool
    // config.eventBus
    // config.runtimeMetricsCollectorConfig
    // config.networkLatencyMetricsCollectorConfig
    // config.defaultMetricsLoggingConsumer

    if( len( arguments.config.propertyFile ) ) {
      
      var fis = CreateObject( 'java', 'java.io.FileInputStream' ).init( arguments.config.propertyFile );
      var propertyFile = newJava( "java.util.Properties" ).init();
      propertyFile.load( fis );
      fis.close();
      var SystemPropertyLoader = newJava( "com.couchbase.client.core.env.SystemPropertyPropertyLoader" )
        .init( propertyFile ); 
        
      builder.load( SystemPropertyLoader )
    }

    var coreEnvironment = builder.build();
    var exportedConfigJSON = coreEnvironment.exportAsString( ExportFormat.JSON_PRETTY );
    writeDump( output='console', var="CFCouchbase SDK bootstrapped with the following configuration: #chr(13)##chr(10)#" & exportedConfigJSON );
    
    return coreEnvironment;
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
  * @options.hint Java options object
  * @Return The argument collection with the defaulted values.
  */
  public any function defaultPersistReplicate( required struct args, required options )  {
    var validPersistTo = "NONE,ACTIVE,ONE,TWO,THREE,FOUR";
    var validReplicateTo = "NONE,ONE,TWO,THREE";
    // persistTo
    if( structKeyExists( args, "persistTo" ) ) {
      args['persistTo'] = trim( args.persistTo );
      // if the value is ZERO set it to NONE for backwards compatibility
      if( args.persistTo == "ZERO" ) {
        args['persistTo'] = "NONE";
      }
      if( args.persistTo == "MASTER" ) {
        args['persistTo'] = "ACTIVE";
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

    options.durability( args['persistTo'], args['replicateTo'] )
    return options;
  }

  /**
  * Default timeout in arguments.  Will create "timeout" with a default value specified in settings
  *
  * @args.hint The argument collection to process
  * @options.hint Java options object
  *
  * @Return The argument collection with the defaulted values.
  */
  public any function defaultTimeout( required args, required options ) {

    args['timeout'] = !structKeyExists( args, "timeout" ) ? variables.couchbaseConfig.getDefaultTimeout() : args.timeout;

    // Validate timeout
    if( !isNumeric( args.timeout ) || args.timeout < 0 ) {
      throw(
        message="Invalid timeout value of [" & args.timeout & "]",
        detail="Valid values are positive integers",
        type="InvalidTimeout"
      );
    }
    options.expiry( Duration.ofMinutes( args.timeout ) );
    return options;
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
