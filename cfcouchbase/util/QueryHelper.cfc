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
    this['stale'] = variables.client.newJava( "com.couchbase.client.java.view.Stale" );
    this['scanConsistency'] = variables.client.newJava( "com.couchbase.client.java.query.consistency.ScanConsistency" );

    // Java Time Units
    variables['timeUnit'] = createObject( "java", "java.util.concurrent.TimeUnit" );

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
          if( !listFindNoCase( "false,true,ok,update_after", arguments.options[ key ] ) ) {
            throw(
              message="Invalid " & key & " value of " & arguments.options[ key ],
              detail="Valid values are ok, update_after and false.",
              type="CouchbaseClient.Invalid" & key
            );
          }
          // set the stale value to the key enum, the value "ok" is no longer supported
          // so normalize it to "true"
          opts[ key ] = this.stale[uCase( arguments.options[ key ] == "ok" ? "true" : arguments.options[ key ] )];
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
          // keys has to be set as a com.couchbase.client.java.document.json.JsonArray object
          opts['keys'] = variables.client.newJava( "com.couchbase.client.java.document.json.JsonArray" )
            .create()
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
        castKey = variables.client.newJava( "com.couchbase.client.java.document.json.JsonArray" )
          .create()
          .from( arguments.key );
      break;
      case "struct":
        castKey = variables.client.newJava( "com.couchbase.client.java.document.json.JsonObject" )
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
      n1qlParams = variables.client.newJava( "com.couchbase.client.java.document.json.JsonArray" ).from( arguments.parameters );
    }
    else { // we are dealing with named params
      // loop over all of the params and javaCast them as the sdk expects explicit types
      for( var param in arguments.parameters ) {
        arguments['parameters'][ param ] = castN1qlParameter( arguments.parameters[ param ] );
      }
      n1qlParams = variables.client.newJava( "com.couchbase.client.java.document.json.JsonObject" ).from( arguments.parameters );
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
  */
  public any function processN1qlOptions( required any options ) {
    var n1qlParams = variables.client.newJava( "com.couchbase.client.java.query.N1qlParams" ).build();
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
      n1qlParams = n1qlParams.adhoc( javaCast( "boolean", arguments.options.adhoc ) );
    }
    // is there consistency?
    if( structKeyExists( arguments.options, "consistency" ) ) {
      // make sure the consistency is valid
      if( !listFindNoCase( "NOT_BOUNDED,REQUEST_PLUS,STATEMENT_PLUS", arguments.options.consistency ) ) {
        throw(
          message="Invalid consistency Value",
          detail="Invalid consistency value, valid values are: NOT_BOUNDED, REQUEST_PLUS, STATEMENT_PLUS",
          type="CouchbaseClient.N1qlParam.ConsistencyException"
        );
      }
      // set the consistency from the enum
      n1qlParams = n1qlParams.consistency( this.scanConsistency[uCase( arguments.options.consistency )] );
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
      n1qlParams = n1qlParams.maxParallelism( javaCast( "int", arguments.options.maxParallelism ) );
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
      n1qlParams = n1qlParams.scanWait(
        javaCast( "long", arguments.options.scanWait ),
        variables.timeUnit.MILLISECONDS
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
      n1qlParams = n1qlParams.serverSideTimeout(
        javaCast( "long", arguments.options.serverSideTimeout ),
        variables.timeUnit.MILLISECONDS
       );
    }
    // is there a clientContextId?
    if( structKeyExists( arguments.options, "clientContextId" ) ) {
      if( !isSimpleValue( arguments.options.clientContextId ) ) {
        throw(
          message="Invalid clientContextId Value",
          detail="The value for clientContextId must be a string",
          type="CouchbaseClient.N1qlParam.ClientContextIdException"
        );
      }
      // set the clientContextId
      n1qlParams = n1qlParams.withContextId( javaCast( "string", arguments.options.clientContextId ) );
    }
    return n1qlParams;
  }

}