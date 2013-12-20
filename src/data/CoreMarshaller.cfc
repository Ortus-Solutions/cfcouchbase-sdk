/**
* Copyright Since 2005 Ortus Solutions, Corp
* www.coldbox.org | www.luismajano.com | www.ortussolutions.com | www.gocontentbox.org
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALING
* IN THE SOFTWARE.
********************************************************************************
* @author Luis Majano, Brad Wood
* This is our data marshaller interface for serializing and deserializing objects from Couchbase to CFML and vice-versa
*/
component accessors="true"{

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
	function init(){

		variables.objectMDCache = createObject( "java", "java.util.HashMap" ).init();

		return this;
	}

	/**
	* A method that is called by the couchbase client upon creation so if the marshaller implemnts this function, it can talk back to the client.
	*/
	any function setCouchbaseClient( required couchcbaseClient ){
		variables.couchbaseClient = arguments.couchcbaseClient;
		return this;
	}

	/**
	* This method deserializes an incoming data string via JSON and according to our rules. It can also accept an optional 
	* inflateTo parameter wich can be an object we should inflate our data to.
	* @data.hint A JSON document to deserialize according to our rules
	* @inflateTo.hint The object that will be used to inflate the data with according to our conventions
	* @deserialize.hint The boolean value that marks if we should deserialize or not. Default is true
	*/
	any function deserializeData( required string data, any inflateTo="", boolean deserialize=true ){
		var results = arguments.data;
		
		// no deserializations
		if( !arguments.deserialize ){ return arguments.data; }

		// do custom deserializations here.
		if( arguments.deserialize && isJSON( arguments.data ) ){
			// Deserialize JSON
			results = deserializeJSON( arguments.data );
			
			// Do we have a cfcouchbase CFC memento to inflate?
			if( isStruct( results ) and structkeyExists( results, "type" ) and results.type eq "cfcouchbase-cfcdata" ){
				// try to inflate it back:
				var oTarget = new "#results.classpath#"();
				for( var thisProp in results.data ){
					evaluate( "oTarget.set#thisProp#( results.data[ thisProp ] )" );
				}
				results = oTarget;
			}
			// Do we have a cfcouchbase native CFC?
			else if( isStruct( results ) and structkeyExists( results, "type" ) and results.type eq "cfcouchbase-cfc" ){
				results = objectLoad( toBinary( results.binary  ) );
			}
			// Do we have a cfcouchbase query?
			else if( isStruct( results ) and structkeyExists( results, "type" ) and results.type eq "cfcouchbase-query" ){
				results = objectLoad( toBinary( results.binary  ) );
			}

			// Do inflations here
		}
		
		return results;
	}

	/**
	* This method serializes incoming data according to our rules and it returns a string representation usually JSON
	* @data.hint The data to serialize
	*/
	string function serializeData( required any data ){
		
		// if json, or string, just return back no serialization needed
		if( isJSON( arguments.data ) OR isSimpleValue( arguments.data ) ){ return arguments.data; }

		// if objects?
		if( isObject( arguments.data ) ){
			
			// Check if the object has a method called "$serialize", if it does, call it and return
			if( structKeyExists( arguments.data, "$serialize" ) ){
				return arguments.data.$serialize();
			}

			// else let's get its metadata to get it's properties and build a memento out of it.
			var mdCache = getObjectMD( arguments.data );
			if( arrayLen( mdCache.properties ) ){
				var nativeObject = { 
					"type"		= "cfcouchbase-cfcdata",
					"data" 		= {}, 
					"classpath" = mdCache.name 
				};
				// build out a memento from the properties.
				for( var thisProp in mdCache.properties ){
					nativeObject.data[ "#thisProp.name#" ] = evaluate( "arguments.data.get#thisProp.name#()" );
				}
				return serializeJSON( nativeObject );
			}

			// Do native serialization, by default
			return serializeJSON( { 
				"type" = "cfcouchbase-cfc",
				"binary" = toBase64( objectSave( arguments.data ) ),
				"classpath" = mdCache.name
			} );

		}
		// if query, then do native serialization
		else if( isQuery( arguments.data ) ){
			var nativeQuery = { 
				"binary" : toBase64( objectSave( arguments.data ) ),
				"type"="cfcouchbase-query", 
				"recordcount"=arguments.data.recordcount, 
				"columnlist"="#arguments.data.columnlist#" 
			};
			return serializeJSON( nativeQuery );
		}
		// if struct or array just serialize it back with native JSON
		else{
			return serializeJSON( arguments.data );
		}
	}

	/**
	* Get the md of an object
	*/
	struct function getObjectMD( required target ){

		if( !variables.objectMDCache.containsKey( arguments.target ) ){
			lock name="cfcouchbase.marshallercache" type="exclusive" timeout="10" throwOnTimeout="true"{
				if( !variables.objectMDCache.containsKey( arguments.target ) ){
					variables.objectMDCache.put( arguments.target, variables.couchbaseClient.getUtil().getInheritedMetaData( arguments.target ) );	
				}
			}
		}

		return variables.objectMDCache.get( arguments.target );
	}

	/**
	* Clear the metadata cache
	*/
	any function clearObjectCache(){
		variables.objectMDCache.clear();
		return this;
	}

}