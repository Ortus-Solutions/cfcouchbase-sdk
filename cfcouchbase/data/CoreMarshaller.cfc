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
		variables.ObjectPopulator = new cfcouchbase.data.ObjectPopulator();

		return this;
	}
	
	
	// ************************ Serialization ************************ 

	/**
	* This method serializes incoming data according to our rules and it returns a string representation usually JSON
	* @data.hint The data to serialize
	*/
	string function serializeData( required any data ){
		
		// if json, or string, just return back no serialization needed
		if( isJSON( arguments.data ) OR isSimpleValue( arguments.data ) ){ return arguments.data; }

		// if objects?
		if( isObject( arguments.data ) ){
			return serializeObjects( arguments.data );
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
	* Does object data serializations
	*/
	private function serializeObjects( required any data ){
		// Check if the object has a method called "$serialize", if it does, call it and return
		if( structKeyExists( arguments.data, "$serialize" ) ){
			return arguments.data.$serialize();
		}

		// Get object info
		var mdCache = getObjectMD( arguments.data );

		// Auto Inflate Mode, store with class information
		if( structKeyExists( mdCache, "autoInflate" ) AND arrayLen( mdCache.properties ) ){
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
		// else just store properties as data
		else if( structKeyExists( mdCache, "properties" ) and arrayLen( mdCache.properties ) ){
			var nativeData = {};
			// build out a memento from the properties.
			for( var thisProp in mdCache.properties ){
				nativeData[ "#thisProp.name#" ] = evaluate( "arguments.data.get#thisProp.name#()" );
			}
			return serializeJSON( nativeData );
		}

		// Do native serialization, by default
		return serializeJSON( { 
			"type" = "cfcouchbase-cfc",
			"binary" = toBase64( objectSave( arguments.data ) ),
			"classpath" = mdCache.name
		} );
	}


	// ************************ Deserialization ************************ 

	/**
	* This method deserializes an incoming data string via JSON and according to our rules. It can also accept an optional 
	* inflateTo parameter wich can be an object we should inflate our data to.
	* @data.hint A JSON document to deserialize according to our rules
	* @inflateTo.hint The object that will be used to inflate the data with according to our conventions
	* @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
	*/
	any function deserializeData( required string data, any inflateTo="", deserializeOptions={} ){
		var results = arguments.data;

		if( isJSON( arguments.data ) ){
			// Deserialize JSON
			results = deserializeJSON( arguments.data );
			
			// Do we have a cfcouchbase CFC memento to inflate?
			if( isStruct( results ) and structkeyExists( results, "type" ) and results.type eq "cfcouchbase-cfcdata" ){
				
				// Use class path from JSON unless it's being overridden
				if( isSimpleValue( arguments.inflateTo ) && !len( trim( arguments.inflateTo ) ) ) {
					arguments.inflateTo = results.classpath;
				}
				
				return deserializeObjects( results.data, arguments.inflateTo, arguments.deserializeOptions );
			}
			// Do we have a cfcouchbase native CFC?
			else if( isStruct( results ) and structkeyExists( results, "type" ) and results.type eq "cfcouchbase-cfc" ){
				// this is an object already, just return, no inflations necessary
				return objectLoad( toBinary( results.binary  ) );
			}
			// Do we have a cfcouchbase query?
			else if( isStruct( results ) and structkeyExists( results, "type" ) and results.type eq "cfcouchbase-query" ){
				results = objectLoad( toBinary( results.binary  ) );
			}

		}
		
		// If there's an inflateTo, then we're sending back a CFC!
		if( !isSimpleValue( arguments.inflateTo ) || len( trim( arguments.inflateTo ) ) ){
			return deserializeObjects( results, arguments.inflateTo, arguments.deserializeOptions );
		}		
		
		// We reach this if it's not JSON, or we're not inflating to a CFC
		return results;
	}
	/**
	* Does object inflation
	*/
	private function deserializeObjects( required any data, required any inflateTo, deserializeOptions={} ){
		var oTarget = '';

		if( isStruct( arguments.data ) ) {			
			oTarget = generateInflatable( arguments.inflateTo, arguments.data );
			
			// Check if the object has a method called "$deserialize", if it does, call it and return
			if( structKeyExists( oTarget, "$deserialize" ) ){
				oTarget.$deserialize( arguments.data );
				return oTarget;
			}
			
			arguments.deserializeOptions.target = oTarget;
			arguments.deserializeOptions.memento = arguments.data;
			
			return ObjectPopulator.populateFromStruct( argumentCollection = arguments.deserializeOptions );
			
		} else if( isQuery( arguments.data ) ) {
			
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
			
		// Non-JSON string
		} else {
			
			oTarget = generateInflatable( arguments.inflateTo, arguments.data );
			
			// Check if the object has a method called "$deserialize", if it does, call it and return
			if( structKeyExists( oTarget, "$deserialize" ) ){
				oTarget.$deserialize( arguments.data );
				return oTarget;
			}

			// They gave us an inflateTo, but we don't know how to use this data type
			return arguments.data;
			
		}
		
	}

	// ************************ Utility ************************ 


	/**
	* A method that is called by the couchbase client upon creation so if the marshaller implemnts this function, it can talk back to the client.
	*/
	any function setCouchbaseClient( required couchcbaseClient ){
		variables.couchbaseClient = arguments.couchcbaseClient;
		return this;
	}
	
	/**
	* Generates inflatable CFC from a class path or closure provider 
	*/
	private function generateInflatable( required any inflateTo, required any data ){
		
		if( isSimpleValue( arguments.inflateTo ) ) {
			// Treat as a class path
			return new "#arguments.inflateTo#"();
		} else if( isObject( arguments.inflateTo ) ) {
			return arguments.inflateTo;
		} else {
			// Call as a provider.  The provider gets to peek at the data
			// in case that determines what kind of object to build
			return arguments.inflateTo( arguments.data );
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