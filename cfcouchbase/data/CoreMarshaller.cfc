/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>Our core marshaller is in charge of serializing/deserializing between CFML and Couchbase according to our rules. Please see
* the documentation for further information.</p>
* @author Luis Majano, Brad Wood, Aaron Benton
*/
component accessors="true" implements="cfcouchbase.data.IDataMarshaller" {

  /**
  * The link back to the couchbase client.
  */
  property name="couchbaseClient";

  /**
  * A struct holding metadata cache for objects
  */
  property name="objectMDCache" type="struct";

  /**
  * Constructor
  */
  function init() {
    variables['system'] = createObject( "java", "java.lang.System" );
    variables['objectPopulator'] = new cfcouchbase.data.ObjectPopulator();
    return this;
  }

  // ************************ Serialization ************************

  /**
  * This method serializes incoming data according to our rules and it returns a string representation usually JSON
  * @data.hint The data to serialize
  */
  public string function serializeData( required any data ) {

    // if json or a number just return back no serialization needed
    if( isJSON( arguments.data ) || isNumeric( arguments.data ) ) {
      return arguments.data;
    }

    // binary objects need to be com.couchbase.client.deps.io.netty.buffer.ByteBuf
/*    if( isBinary( arguments.data ) ) {
      return variables.Unpooled.copiedBuffer(arguments.data);
    }
*/
    // if string wrap it in quotes and return it
    // this is required otherwise it is seen as a binary document
    if( isSimpleValue( arguments.data ) ) {
      return arguments.data;
    }

    // if objects?
    if( isObject( arguments.data ) ) {
      return serializeObjects( arguments.data );
    }
    // if query, then do native serialization
    else if( isQuery( arguments.data ) ) {
      var nativeQuery = {
        "data" = arguments.data,
        "type" = "cfcouchbase-query2",
        "recordcount" = arguments.data.recordcount,
        "columnlist" = arguments.data.columnlist
      };
      return serializeJSON( nativeQuery );
    }
    // if struct or array just serialize it back with native JSON
    else {
      return serializeJSON( arguments.data );
    }
  }

  /**
  * Does object data serializations
  */
  private function serializeObjects( required any data ) {
    // Check if the object has a method called "$serialize", if it does, call it and return
    if( structKeyExists( arguments.data, "$serialize" ) ) {
      return arguments.data.$serialize();
    }

    // Get object info
    var mdCache = variables.couchbaseClient.getUtil().getInheritedMetaData( arguments.data );

    // Auto Inflate Mode, store with class information
    if( structKeyExists( mdCache, "autoInflate" ) && arrayLen( mdCache.properties ) ) {
      var nativeObject = {
        "type"    = "cfcouchbase-cfcdata",
        "data"     = buildMemento( arguments.data, mdCache ),
        "classpath" = mdCache.name
      };
      return serializeJSON( nativeObject );
    }
    // else just store properties as data
    else if( structKeyExists( mdCache, "properties" ) && arrayLen( mdCache.properties ) ) {
      var nativeData = buildMemento( arguments.data, mdCache );
      return serializeJSON( nativeData );
    }

    // Do native serialization, by default
    return serializeJSON( {
      "type" = "cfcouchbase-cfc",
      "binary" = toBase64( objectSave( arguments.data ) ),
      "classpath" = mdCache.name
    } );
  }

  /**
  * build CFC memento
  */
  private function buildMemento( required any target, required any metaData ) {
    var memento = {};
    // build out a memento from the properties.
    for( var thisProp in arguments.metaData.properties ) {
      if( !structKeyExists( thisProp, "inject" ) ) {
        memento[ thisProp.name ] = evaluate( "arguments.target.get" & thisProp.name & "()" );
      }
    }
    return memento;
  }

  // ************************ Deserialization ************************

  /**
  * This method deserializes an incoming data string via JSON and according to our rules. It can also accept an optional
  * inflateTo parameter wich can be an object we should inflate our data to.
  * @ID.hint The ID of the document being deserialized
  * @data.hint A JSON document to deserialize according to our rules
  * @inflateTo.hint The object that will be used to inflate the data with according to our conventions
  * @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
  */
  public any function deserializeData(
    required string id,
    required any data,
    any inflateTo="",
    struct deserializeOptions={}
  ) {
    var results = arguments.data;
    // is the data json? if so convert it.  it may not be json if it is a binary, string (that's not json),
    // atomic integer document.  or someone could have their own data marshaller and is calling this as the
    // super
    if( isJSON( arguments.data ) ) {
      // Deserialize JSON
      if( structKeyExists( arguments.deserializeOptions, "JSONStrictMapping" ) ) {
        results = deserializeJSON( arguments.data, arguments.deserializeOptions.JSONStrictMapping );
      } else {
        results = deserializeJSON( arguments.data, false );
      }
    } /* else if ( arguments.data.getClass() contains "com.couchbase.client.deps.io.netty.buffer" ) { // is it ByteBuf?
      // create a new empty byte array sized with the number of bytes from the ByteBuf
      results = createObject("java","java.lang.reflect.Array").newInstance(
       createObject("java", "java.io.ByteArrayOutputStream").init().toByteArray().getClass().getComponentType(),
       arguments.data.readableBytes()
      );
      // read the bytes from the start of the ByteBuf to the end copying them into the results
      arguments.data.getBytes(javaCast("int", 0), results);
      // binary documents implement com.couchbase.client.deps.io.netty.buffer.ByteBuf which are unpooled.  when a binary
      // document is retrieved from by the SDK it must be released.  We use the safeRelease() method instead of release(),
      // release() will return true if class implements com.couchbase.client.deps.io.netty.util.ReferenceCounted if not
      // it will return false.  However if there are no references to release and ReferenceCounted is implemented release()
      // will throw an exception, safeRelease() does not as it traps and returns void regardless
      variables.ReferenceCountUtil.safeRelease(arguments.data);
    } else if(isBinary(arguments.data)) { // if the data is binary
      // Means a LegacyDocument was created and returned, someone more than likely called the get() method w/o specifcying the
      // data type and while a binary object is returned the ByteBuf will reamin open and we need to close it
      variables.ReferenceCountUtil.safeRelease(arguments.data);
    }
*/
    // is it a structure that has our custom type values?
    if ( isStruct( results ) && structKeyExists( results, "type" ) && isSimpleValue( results.type ) ) {
      switch (results.type) {
        // Do we have a cfcouchbase CFC memento to inflate?
        case "cfcouchbase-cfcdata":
          // Use class path from JSON unless it's being overridden
          if( isSimpleValue( arguments.inflateTo ) && !len( trim( arguments.inflateTo ) ) ) {
            arguments['inflateTo'] = results.classpath;
            return deserializeObjects( arguments.id, results.data, arguments.inflateTo, arguments.deserializeOptions );
          }
        break;
        // Do we have a cfcouchbase native CFC?
        case "cfcouchbase-cfc":
          // this is an object already, just return, no inflations necessary
          return objectLoad( toBinary( results.binary  ) );
        break;
        // Do we have a cfcouchbase query?
        case "cfcouchbase-query": // DEPRECATED
          // this is an object already, just return, no inflations necessary
          return objectLoad( toBinary( results.binary  ) );
        break;
        // Do we have a cfcouchbase query?
        case "cfcouchbase-query2":
          // this is an object already, just return, no inflations necessary
          results = results.data;
        break;
      }
    }

    // If there's an inflateTo, then we're sending back a CFC!
    if( !isSimpleValue( arguments.inflateTo ) || len( trim( arguments.inflateTo ) ) ) {
      return deserializeObjects( arguments.id, results, arguments.inflateTo, arguments.deserializeOptions );
    }

    // We reach this if it's not JSON, or we're not inflating to a CFC, maybe binary, string or number? ¯\_(ツ)_/¯
    return results;
  }

  /**
  * Does object inflation
  */
  private function deserializeObjects(
    required string ID,
    required any data,
    required any inflateTo,
    deserializeOptions= {}
  ) {
    var oTarget = "";
    var propertyIDName = "";

    if( isStruct( arguments.data ) ) {
      oTarget = generateInflatable( arguments.inflateTo, arguments.data );

      // Check if the object has a method called "$deserialize", if it does, call it and return
      if( structKeyExists( oTarget, "$deserialize" ) ) {
        oTarget.$deserialize( arguments.id, arguments.data );
        return oTarget;
      }

      // Determine what this CFC calls its ID
      propertyIDName = determineIDPropertyName( oTarget, arguments.deserializeOptions );
      // If it's not already in the struct...
      if( len( propertyIDName ) && !structKeyExists( arguments.data, propertyIDName ) ) {
        // ... put it there
        arguments.data[ propertyIDName ] = arguments.ID;
      }

      arguments.deserializeOptions.target = oTarget;
      arguments.deserializeOptions.memento = arguments.data;

      return variables.objectPopulator.populateFromStruct( argumentCollection = arguments.deserializeOptions );

    }
    else if( isQuery( arguments.data ) ) {

      // Loop over query and inflate a CFC for each row
      var results = [];
      var i = 0;

      while( ++i <= arguments.data.recordCount ) {

        arguments.deserializeOptions.target = generateInflatable( arguments.inflateTo, arguments.data );
        arguments.deserializeOptions.qry = arguments.data;
        arguments.deserializeOptions.rowNumber = i;

        arrayAppend( results, ObjectPopulator.populateFromQuery( argumentCollection = arguments.deserializeOptions ) );
      }

      return results;
    }
    else { // Non-JSON string

      oTarget = generateInflatable( arguments.inflateTo, arguments.data );

      // Check if the object has a method called "$deserialize", if it does, call it and return
      if( structKeyExists( oTarget, "$deserialize" ) ) {
        oTarget.$deserialize( arguments.id, arguments.data );
        return oTarget;
      }

      // They gave us an inflateTo, but we don't know how to use this data type
      return arguments.data;

    }

  }

  // ************************ Utility ************************

  /**
  * A method that is called by the couchbase client upon creation so if the marshaller implements this function, it can talk back to the client.
  */
  public any function setCouchbaseClient( required couchcbaseClient ) {
    variables['couchbaseClient'] = arguments.couchcbaseClient;
    return this;
  }

  /**
  * Generates inflatable CFC from a class path, object or closure provider
  */
  private function generateInflatable( required any inflateTo, required any data ) {
    if( isSimpleValue( arguments.inflateTo ) ) {
      // Treat as a class path
      return new "#arguments.inflateTo#"();
    }
    else if( isCustomFunction( arguments.inflateTo) or $isClosure( arguments.inflateTo) ) {
      // Call as a provider.  The provider gets to peek at the data
      // in case that determines what kind of object to build
      return arguments.inflateTo( arguments.data );
    }
    else if( isObject( arguments.inflateTo ) ) {
      return arguments.inflateTo;
    }
  }

  private boolean function $isClosure( required any target ) {
    return structkeyExists( getFunctionList(), "isClosure") ? isClosure( arguments.target ) : false;
  }

  /**
  * Determine which property of the CFC is the primary ID.  Returns empty string if none found.
  */
  private string function determineIDPropertyName( required any target, required struct deserializeOptions ) {
    var md = variables.couchbaseClient.getUtil().getInheritedMetaData( arguments.target );

    // Look at the properties in the CFC
    if( structKeyExists( md, "properties" ) ) {
      // Search for a fieldtype of ID
      for( var thisProp in md.properties ) {
        if( structKeyExists( thisProp, "fieldtype" ) && thisProp.fieldtype == "ID" ) {
          // And return its name
          return thisProp.name;
        }
      }
    }

    // If none found, allow the IDPropertyName to be passed via the deserializeOptions
    if( structKeyExists( deserializeOptions, "IDPropertyName" ) ) {
      return deserializeOptions.IDPropertyName;
    }

    // Not found
    return "";

  }

}
