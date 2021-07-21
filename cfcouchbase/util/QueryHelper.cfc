/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>This class processes Couchbase query options from CFML to Java</p>
* @author Luis Majano, Brad Wood, Aaron Benton
*/
component accessors="true" {
  /**
  * Constructor
  */
  public QueryHelper function init( required client ) {
    variables['client'] = arguments.client;

    // load enums
    this['ViewScanConsistency'] = variables.client.newJava( "com.couchbase.client.java.view.ViewScanConsistency" );
    this['QueryScanConsistency'] = variables.client.newJava( "com.couchbase.client.java.query.QueryScanConsistency" );
    this['QueryProfile'] = variables.client.newJava( "com.couchbase.client.java.query.QueryProfile" );

    // Java Time Units
    variables['timeUnit'] = createObject( "java", "java.util.concurrent.TimeUnit" );
    variables['JsonArray'] = variables.client.newJava( "com.couchbase.client.java.json.JsonArray" );
    variables['JsonObject'] = variables.client.newJava( "com.couchbase.client.java.json.JsonObject" );
    
    variables['Duration'] = variables.client.newJava( "java.time.Duration" );

    

    // utility
    variables['util'] = variables.client.getUtility();
    return this;
  }

  /**
  * Process query options
  * @options.hint the options structure
  */
  public struct function processOptions( required struct options ) {
    var opts = {};
    var dataType = "";
    // loop over each of the options
    for( var key in arguments.options ) {
      // process certain keys independently
      switch( key ) {
        // validate / set numerics groupLevel, limit, skip and offset
        case "groupLevel":
        case "limit":
        case "skip":
        case "offset":  {
          // make sure the value is numeric and greater than or equal to 0
          if( !isNumeric( arguments.options[ key ] ) || arguments.options[ key ] < 0 ) {
            throw(
              message="Invalid " & key & " value of " & arguments.options[ key ],
              detail="Valid values are non-negative integers.",
              type="CouchbaseClient.Invalid" & key
            );
          }
          else if( key == "offset" ) { // the url param is actually "skip"
            opts['skip'] = javaCast( "int", int( arguments.options[ key ] ) );
          }
          else {
            opts[ key ] = javaCast( "int", int( arguments.options[ key ] ) );
          }
          break;
        }
        // validate / set booleans debug, descending, development, group, inclusiveEnd, includeDocs and reduce
        case "debug":
        case "descending":
        case "development":
        case "group":
        case "inclusiveEnd":
        case "includeDocs":
        case "reduce":  {
          // make sure the value is a boolean
          if( !isBoolean( arguments.options[ key ] ) ) {
            throw(
              message="Invalid " & key & " value of " & arguments.options[ key ],
              detail="Valid values are TRUE and FALSE.",
              type="CouchbaseClient.Invalid" & key
            );
          }
          // set the value if it is not group, or if it is group and the groupLevel option wasn't passed
          if( key != "group" || !structKeyExists( arguments.options, "groupLevel" ) ) {
            opts[ key ] = javaCast( "boolean", arguments.options[ key ] ? true : false );
          }
          break;
        }
        // validate the stale parameter
        case "stale":  {
          if( arguments.options[ key ] == 'false' ) {
            arguments.options[ key ] = 'REQUEST_PLUS';
          }
          if( arguments.options[ key ] == 'OK' ) {
            arguments.options[ key ] = 'NOT_BOUNDED';
          }
          if( !listFindNoCase( "NOT_BOUNDED,REQUEST_PLUS,UPDATE_AFTER", arguments.options[ key ] ) ) {
            throw(
              message="Invalid " & key & " value of " & arguments.options[ key ],
              detail="Valid values are NOT_BOUNDED, REQUEST_PLUS, and UPDATE_AFTER.",
              type="CouchbaseClient.Invalid" & key
            );
          }
          opts[ key ] = this.ViewScanConsistency[uCase( arguments.options[ key ] )];
          break;
        }
      
        // validate / set the sortOrder option
        case "sortOrder":  {
          var sortOrder = arguments.options[ 'sortOrder' ];
          if( arguments.options[ key ] == "ASC" ) {
            opts['descending'] = javaCast( "boolean", false );
          }
          else if( arguments.options[ key ] == "DESC" )  {
            opts['descending'] = javaCast( "boolean", true );
          }
          else {
            throw(
              message="Invalid " & key & " value of " & arguments.options[ key ],
              detail="Valid values are ASC and DESC.",
              type="CouchbaseClient.InvalidSortOrder"
            );
          }
          break;
        }
        // startKeys
        case "startKey":
        case "rangeStart":  {
          opts['startKey'] = castViewKey( arguments.options[ key] );
          break;
        }
        // endKeys
        case "endKey":
        case "rangeEnd":  {
          opts['endKey'] = castViewKey( arguments.options[ key] );
          break;
        }
        // keys
        case "key":  {
          opts['key'] = castViewKey( arguments.options[ key] );
          break;
        }
        case "keys":  {
          // keys has to be set as a com.couchbase.client.java.json.JsonArray object
          opts['keys'] = variables.client.newJava( "com.couchbase.client.java.json.JsonArray" )
            .from( arguments.options[ key ] );
          break;
        }
      }
    }
    // if group or groupLevel and not reduce error
    if( ( structKeyExists( arguments.options, "group" ) && arguments.options.group || structKeyExists( arguments.options, "groupLevel" ) ) && structKeyExists( arguments.options, "reduce" ) && !arguments.options.reduce ) {
      throw(
        message="Invalid option for groupLevel",
        detail="The reduce option must be true for a group or groupLevel query",
        type="CouchbaseClient.InvalidOption"
      );
    }
    return opts;
  }

  /**
  * JavaCast View key correctly as the endKey, key and startKey can all be a different type
  * @key.hint The key to cast
  */
  public any function castViewKey( required any key ) {
    var dataType = variables.util.getDataType( arguments.key );
    var castKey = "";
    // key can be string, array, long, double, object, boolean
    switch( dataType ) {
      case "array":
        castKey = variables.client.newJava( "com.couchbase.client.java.json.JsonArray" )
          .create()
          .from( arguments.key );
      break;
      case "struct":
        castKey = variables.client.newJava( "com.couchbase.client.java.json.JsonObject" )
          .create()
          .from( arguments.key );
      break;
      case "long":
        castKey = javaCast( "long", arguments.key );
      break;
      case "double":
        castKey = javaCast( "double", arguments.key );
      break;
      default:
        castKey = javaCast( "string", arguments.key.toString() );
    }
    return castKey;
  }

  /**
  * Process N1ql Parameterized values
  * @parameters.hint The positional or named parameters to the N1ql Query
  */
  public any function processN1qlParameters( required any parameters ) {
    var n1qlParams = "";
    var index = 1;
    // parameters can only be an array or structures
    if( !isArray( arguments.parameters ) && !isStruct( arguments.parameters ) ) {
      throw(
        message="Invalid Parameter Type",
        detail="N1ql query parameters must an be an array or structure",
        type="CouchbaseClient.N1qlParamsException"
      );
    }

    if( isArray( arguments.parameters ) ) { // we are dealing with positional params
      // loop over all of the params and javaCast them as the sdk expects explicit types
      for( var param in arguments.parameters ) {
        arguments['parameters'][ index++ ] = castN1qlParameter( param );
      }
      n1qlParams = JsonArray.from( arguments.parameters );
    }
    else { // we are dealing with named params
      // loop over all of the params and javaCast them as the sdk expects explicit types
      for( var param in arguments.parameters ) {
        arguments['parameters'][ param ] = castN1qlParameter( arguments.parameters[ param ] );
      }
      n1qlParams = JsonObject.from( arguments.parameters );
    }
    return n1qlParams;
  }

  /**
  * JavaCast N1ql param values
  * @value.hint The value to cast
  */
  public any function castN1qlParameter( required any value ) {
    var castValue = arguments.value;
    if( !isSimpleValue( castValue ) ) {
      throw(
        message="Invalid Parameter Value",
        detail="A N1ql query parameter value must be a string, number or boolean.",
        type="CouchbaseClient.N1qlParamException"
      );
    }
    // is it a number?
    if( isNumeric( castValue ) ) {
      // is it a float / double?
      if( find( ".", castValue ) ) {
        castValue = javaCast( "double", castValue );
      }
      else {
        castValue = javaCast( "long", castValue );
      }
    }
    // is it a boolean?
    else if( isBoolean( castValue ) ) {
      castValue = javaCast( "boolean", castValue );
    }
    else {
      castValue = javaCast( "string", castValue );
    }
    return castValue;
  }

  /**
  * Process N1ql Query Options
  * @options.hint The query level options for the N1ql query
  * @options.hint com.couchbase.client.java.query.QueryOptions instance
  */
  public any function processN1qlOptions( required any queryOptions, required any options ) {
    // is there adhoc?
    if( structKeyExists( arguments.options, "adhoc" ) ) {
      // make sure the consistency is value
      if( !isBoolean( arguments.options.adhoc ) ) {
        throw(
          message="Invalid adhoc Value",
          detail="Invalid adhoc value, must be TRUE or FALSE",
          type="CouchbaseClient.N1qlParam.AdhocException"
        );
      }
      // set the adhoc value
      queryOptions.adhoc( javaCast( "boolean", arguments.options.adhoc ) );
    }
    // is there metrics?
    if( structKeyExists( arguments.options, "metrics" ) ) {
      // make sure the consistency is value
      if( !isBoolean( arguments.options.metrics ) ) {
        throw(
          message="Invalid metrics Value",
          detail="Invalid metrics value, must be TRUE or FALSE",
          type="CouchbaseClient.N1qlParam.metricsException"
        );
      }
      // set the adhoc value
      queryOptions.metrics( javaCast( "boolean", arguments.options.metrics ) );
    } else {
      queryOptions.metrics( true );
    }
    // is there consistency?
    if( structKeyExists( arguments.options, "consistency" ) ) {
      // make sure the consistency is valid
      if( arguments.options.consistency == 'STATEMENT_PLUS' ) {
        arguments.options.consistency = 'REQUEST_PLUS';
      }      
      if( !listFindNoCase( "NOT_BOUNDED,REQUEST_PLUS", arguments.options.consistency ) ) {
        throw(
          message="Invalid consistency Value",
          detail="Invalid consistency value, valid values are: NOT_BOUNDED, REQUEST_PLUS",
          type="CouchbaseClient.N1qlParam.ConsistencyException"
        );
      }
      // set the consistency from the enum
      queryOptions.scanConsistency( this.QueryScanConsistency[uCase( arguments.options.consistency )] );
    }
    // is there maxParallelism?
    if( structKeyExists( arguments.options, "maxParallelism" ) ) {
      if( !isNumeric( arguments.options.maxParallelism ) ) {
        throw(
          message="Invalid maxParallelism Value",
          detail="The value for maxParallelism must be numeric",
          type="CouchbaseClient.N1qlParam.MaxParallelismException"
        );
      }
      // set the maxParallelism
      queryOptions.maxParallelism( javaCast( "int", arguments.options.maxParallelism ) );
    }
    // is there a scanWait?
    if( structKeyExists( arguments.options, "scanWait" ) ) {
      if( !isNumeric( arguments.options.scanWait ) ) {
        throw(
          message="Invalid scanWait Value",
          detail="The value for scanWait must be numeric",
          type="CouchbaseClient.N1qlParam.ScanWaitException"
        );
      }
      // set the scanWait
      queryOptions.scanWait(
        Duration.ofMillis( javaCast( "long", arguments.options.scanWait ) )
      );
    }
    // is there a serverSideTimeout?
    if( structKeyExists( arguments.options, "serverSideTimeout" ) ) {
      if( !isNumeric( arguments.options.serverSideTimeout ) ) {
        throw(
          message="Invalid serverSideTimeout Value",
          detail="The value for serverSideTimeout must be numeric",
          type="CouchbaseClient.N1qlParam.ServerSideTimeoutException"
        );
      }
      // set the serverSideTimeout
      queryOptions.timeout(
       Duration.ofMillis( javaCast( "long", arguments.options.serverSideTimeout ) )
       );
    }
    // is there a clientContextId?
    if( structKeyExists( arguments.options, "clientContextId" ) ) {
      if( !isSimpleValue( arguments.options.clientContextId ) ) {
        throw(
          message="Invalid clientContextId Value`",
          detail="The value for clientContextId must be a string",
          type="CouchbaseClient.N1qlParam.ClientContextIdException"
        );
      }
      // set the clientContextId
      queryOptions.clientContextId( javaCast( "string", arguments.options.clientContextId ) );
    }
    // is there a scanCap?
    if( structKeyExists( arguments.options, "scanCap" ) ) {
      if( !isNumeric( arguments.options.scanCap ) ) {
        throw(
          message="Invalid scanCap Value`",
          detail="The value for scanCap must be a int",
          type="CouchbaseClient.N1qlParam.scanCapException"
        );
      }
      // set the scanCap
      queryOptions.scanCap( javaCast( "int", arguments.options.scanCap ) );
    }
    // is there a pipelineCap?
    if( structKeyExists( arguments.options, "pipelineCap" ) ) {
      if( !isNumeric( arguments.options.pipelineCap ) ) {
        throw(
          message="Invalid pipelineCap Value`",
          detail="The value for pipelineCap must be a int",
          type="CouchbaseClient.N1qlParam.pipelineCapException"
        );
      }
      // set the pipelineCap
      queryOptions.pipelineCap( javaCast( "int", arguments.options.pipelineCap ) );
    }
    // is there flexIndex?
    if( structKeyExists( arguments.options, "flexIndex" ) ) {
      // make sure the consistency is flexIndex
      if( !isBoolean( arguments.options.flexIndex ) ) {
        throw(
          message="Invalid flexIndex Value",
          detail="Invalid flexIndex value, must be TRUE or FALSE",
          type="CouchbaseClient.N1qlParam.flexIndexException"
        );
      }
      // set the adhoc value
      queryOptions.flexIndex( javaCast( "boolean", arguments.options.flexIndex ) );
    }
    // is there readonly?
    if( structKeyExists( arguments.options, "readonly" ) ) {
      // make sure the consistency is readonly
      if( !isBoolean( arguments.options.readonly ) ) {
        throw(
          message="Invalid readonly Value",
          detail="Invalid readonly value, must be TRUE or FALSE",
          type="CouchbaseClient.N1qlParam.readonlyException"
        );
      }
      // set the readonly value
      queryOptions.readonly( javaCast( "boolean", arguments.options.readonly ) );
    }
    // is there a pipelineBatch?
    if( structKeyExists( arguments.options, "pipelineBatch" ) ) {
      if( !isNumeric( arguments.options.pipelineBatch ) ) {
        throw(
          message="Invalid pipelineBatch Value`",
          detail="The value for pipelineBatch must be a int",
          type="CouchbaseClient.N1qlParam.pipelineBatchException"
        );
      }
      // set the pipelineBatch
      queryOptions.pipelineBatch( javaCast( "int", arguments.options.pipelineBatch ) );
    }
    // is there a raw?
    if( structKeyExists( arguments.options, "raw" ) ) {
      if( !isStruct( arguments.options.raw ) ) {
        throw(
          message="Invalid raw Value`",
          detail="The value for raw must be a struct",
          type="CouchbaseClient.N1qlParam.rawBatchException"
        );
      }
      // set the raw
      for( var key in arguments.options.raw ) {
        queryOptions.raw( javaCast( "string", key ), arguments.options.raw[ key ] );
      }
    }
    // is there profile?
    if( structKeyExists( arguments.options, "profile" ) ) {
      // make sure the profile is valid
      if( !listFindNoCase( "OFF,PHASES,TIMINGS", arguments.options.profile ) ) {
        throw(
          message="Invalid profile Value",
          detail="Invalid profile value, valid values are: OFF, PHASES, and TIMINGS",
          type="CouchbaseClient.N1qlParam.profileException"
        );
      }
      // set the consistency from the enum
      queryOptions.profile( this.QueryProfile[uCase( arguments.options.profile )] );
    }
    // is there consistentWith?
    if( structKeyExists( arguments.options, "consistentWith" ) ) {
      // make sure the consistentWith is valid
      if( !arguments.options.consistentWith.getClass().getName() == 'com.couchbase.client.java.kv.MutationState' ) {
        throw(
          message="Invalid consistentWith Value",
          detail="Invalid consistentWith value, must be instance of com.couchbase.client.java.kv.MutationState",
          type="CouchbaseClient.N1qlParam.consistentWithException"
        );
      }
      // set the consistency from the enum
      queryOptions.consistentWith( arguments.options.consistentWith );
    }

  }

}