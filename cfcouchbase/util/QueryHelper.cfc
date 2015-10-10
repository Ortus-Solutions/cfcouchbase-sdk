/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>This class processes Couchbase query options from CFML to Java</p>
* @author Luis Majano, Brad Wood
*/
component accessors="true"{
  /**
  * Constructor
  */
  QueryHelper function init( required client ){
    variables.client = arguments.client;
    return this;
  }
  /**
  * Process query options
  * @options.hint the options structure
  */
  public struct function processOptions(required struct options, required any stale){
    var opts = {};
    // loop over each of the options
    for(var key in arguments.options){
      // process certain keys independently
      switch(key){
        // validate / set numerics groupLevel, limit, skip and offset
        case "groupLevel":
        case "limit":
        case "skip":
        case "offset": {
          // make sure the value is numeric and greater than or equal to 0
          if(!isNumeric(arguments.options[key]) || arguments.options[key] < 0){
            throw(message="Invalid " & key & " value of " & arguments.options[key], detail="Valid values are non-negative integers.", type="Invalid " & key);
          }
          else if(key == "offset"){ // the url param is actually "skip"
            opts['skip'] = javaCast("int", int(arguments.options[key]));
          }
          else{
            opts[key] = javaCast("int", int(arguments.options[key]));
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
        case "reduce": {
          // make sure the value is a boolean
          if(!isBoolean(arguments.options[key])){
            throw(message="Invalid " & key & " value of " & arguments.options[key], detail="Valid values are TRUE and FALSE.", type="Invalid " & key);
          }
          // set the value if it is not group, or if it is group and the groupLevel option wasn't passed
          if(key != "group" || !structKeyExists(arguments.options, "groupLevel")){
            opts[key] = javaCast("boolean", arguments.options[key] ? true : false);
          }
          break;
        }
        // validate the stale parameter
        case "stale": {
          if(!listFindNoCase("false,true,ok,update_after", arguments.options[key])){
            throw(message="Invalid " & key & " value of " & arguments.options[key], detail="Valid values are ok, update_after and false.", type="Invalid " & key);
          }
          // set the stale value to the key enum, the value "ok" is no longer supported
          // so normalize it to "true"
          opts[key] = arguments.stale[uCase(key == "ok" ? "true" : arguments.options[key])];
          break;
        }
        // validate / set the sortOrder option
        case "sortOrder": {
          var sortOrder = arguments.options[ 'sortOrder' ];
          if(arguments.options[key] == "ASC"){
            opts['descending'] = javaCast("boolean", false);
          }
          else if(arguments.options[key] == "DESC") {
            opts['descending'] = javaCast("boolean", true);
          }
          else{
            throw(message="Invalid " & key & " value of " & arguments.options[key], detail="Valid values are ASC and DESC.", type="Invalid " & key);
          }
          break;
        }
        // startKeys
        case "startKey":
        case "rangeStart": {
          opts['startKey'] = isSimpleValue(arguments.options[key]) ? """" & arguments.options[key] & """" : serializeJSON(arguments.options[key]);
          break;
        }
        // endKeys
        case "endKey":
        case "rangeEnd": {
          opts['endKey'] = isSimpleValue(arguments.options[key]) ? """" & arguments.options[key] & """" : serializeJSON(arguments.options[key]);
          break;
        }
        // keys
        case "key": {
          opts['key'] = isSimpleValue(arguments.options[key]) ? """" & arguments.options[key]& """" : serializeJSON(arguments.options[key]);
          break;
        }
        case "keys": {
          // keys has to be set as a com.couchbase.client.java.document.json.JsonArray object
          opts['keys'] = variables.client.newJava("com.couchbase.client.java.document.json.JsonArray")
                                                                                                      .create()
                                                                                                      .from(arguments.options[key]);
          break;
        }
      }
      // if group or groupLevel and not reduce error
      if((structKeyExists(arguments.options, "group") && arguments.options.group || structKeyExists(arguments.options, "groupLevel")) && structKeyExists(arguments.options, "reduce") && !arguments.options.reduce){
        throw(message="Invalid option for groupLevel", detail="The reduce option must be true for a group or groupLevel query", type="Invalid Option");
      }
    }
    return opts;
  }
}