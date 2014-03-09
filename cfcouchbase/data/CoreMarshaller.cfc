/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>Our core marshaller is in charge of serializing/deserializing between CFML and Couchbase according to our rules. Please see
* the documentation for further information.</p>
* @author Luis Majano, Brad Wood
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
	function init(){
		variables.system 			= createObject( "java", "java.lang.System" );
		variables.objectPopulator 	= new cfcouchbase.data.ObjectPopulator();

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
		var mdCache = variables.couchbaseClient.getUtil().getInheritedMetaData( arguments.data );

		// Auto Inflate Mode, store with class information
		if( structKeyExists( mdCache, "autoInflate" ) AND arrayLen( mdCache.properties ) ){
			var nativeObject = { 
				"type"		= "cfcouchbase-cfcdata",
				"data" 		= buildMemento( arguments.data, mdCache ),
				"classpath" = mdCache.name 
			};
			return serializeJSON( nativeObject );
		} 
		// else just store properties as data
		else if( structKeyExists( mdCache, "properties" ) and arrayLen( mdCache.properties ) ){
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
	private function buildMemento( required any target, required any metaData ){
		var memento = {};
		// build out a memento from the properties.
		for( var thisProp in arguments.metaData.properties ){
			if( !structKeyExists( thisProp, 'inject' ) ) {
				memento[ "#thisProp.name#" ] = evaluate( "arguments.target.get#thisProp.name#()" );
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
	any function deserializeData( 
		required string ID, 
		required string data, 
		any inflateTo="", 
		struct deserializeOptions={} 
	){
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
				
				return deserializeObjects( arguments.ID, results.data, arguments.inflateTo, arguments.deserializeOptions );
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
			return deserializeObjects( arguments.ID, results, arguments.inflateTo, arguments.deserializeOptions );
		}		
		
		// We reach this if it's not JSON, or we're not inflating to a CFC
		return results;
	}
	/**
	* Does object inflation
	*/
	private function deserializeObjects( 
		required string ID, 
		required any data, 
		required any inflateTo, 
		deserializeOptions={} 
	){
		var oTarget = '';
		var propertyIDName = '';

		if( isStruct( arguments.data ) ) {			
			oTarget = generateInflatable( arguments.inflateTo, arguments.data );
			
			// Check if the object has a method called "$deserialize", if it does, call it and return
			if( structKeyExists( oTarget, "$deserialize" ) ){
				oTarget.$deserialize( arguments.ID, arguments.data );
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
				oTarget.$deserialize( arguments.ID, arguments.data );
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
	* Generates inflatable CFC from a class path, object or closure provider 
	*/
	private function generateInflatable( required any inflateTo, required any data ){
		if( isSimpleValue( arguments.inflateTo ) ) {
			// Treat as a class path
			return new "#arguments.inflateTo#"();
		} else if( isCustomFunction( arguments.inflateTo) or $isClosure( arguments.inflateTo) ) {
			// Call as a provider.  The provider gets to peek at the data
			// in case that determines what kind of object to build
			return arguments.inflateTo( arguments.data );
		} else if( isObject( arguments.inflateTo ) ) {
			return arguments.inflateTo;
		}
	}

	private boolean function $isClosure( required any target ){
		return ( structkeyExists( GetFunctionList(), "isClosure") ? isClosure( arguments.target ) : false );
	}
	
	/**
	* Determine which property of the CFC is the primary ID.  Returns empty string if none found.
	*/
	private string function determineIDPropertyName( required any target, required struct deserializeOptions ){
		var md = variables.couchbaseClient.getUtil().getInheritedMetaData( arguments.target );
		
		// Look at the properties in the CFC
		if( structKeyExists( md, 'properties' ) ){
			// Search for a fieldtype of ID
			for( var thisProp in md.properties ){
				if( structKeyExists( thisProp, 'fieldtype' ) && thisProp.fieldtype == 'ID' ) {
					// And return its name
					return thisProp.name;
				}
			}
		}
		
		// If none found, allow the IDPropertyName to be passed via the deserializeOptions 
		if( structKeyExists( deserializeOptions, 'IDPropertyName' ) ){
			return deserializeOptions.IDPropertyName;
		}
		
		// Not found
		return '';
		
	}

}