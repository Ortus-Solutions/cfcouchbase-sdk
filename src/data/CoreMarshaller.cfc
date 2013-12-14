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
	* This method deserializes an incoming data string via JSON and according to our rules. It can also accept an optional 
	* inflateTo parameter wich can be an object we should inflate our data to.
	* @data.hint A JSON document to deserialize according to our rules
	* @inflateTo.hint The object that will be used to inflate the data with according to our conventions
	* @deserialize.hint The boolean value that marks if we should deserialize or not. Default is true
	*/
	any function deserializeData( required string data, any inflateTo="", boolean deserialize=true ){
		var results = "";

		// no deserializations
		if( !arguments.deserialize ){ return arguments.data; }

		// do custom deserializations here.
		if( arguments.deserialize && isJSON( arguments.data ) ){
			// Deserialize JSON
			results = deserializeJSON( arguments.data );
			
			// Do we have a cfcouchbase query?
			if( isStruct( results ) and structkeyExists( results, "type" ) and results.type eq "cfcouchbase-query" ){
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

			// else let's get its metadata to get it's properties.
			writeDump( getInheritedMetaData( arguments.data ) );abort;

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
	* Returns a single-level metadata struct that includes all items inhereited from extending classes.
	*/
	private function getInheritedMetaData( required component, md={} ){
		// get appropriate metadata
		if( structIsEmpty( arguments.md ) ){
			if( isObject( arguments.component ) ){
				arguments.md = getMetaData( arguments.component );
			} else {
				arguments.md = getComponentMetaData( arguments.component );
			}
		}

		// If it has a parent, stop and calculate it first
			
		if( structKeyExists( arguments.md, "extends" ) AND arguments.md.type eq "component" ){
			local.parent = getInheritedMetaData( component=arguments.component, md=arguments.md.extends );
		} else {
			//If we're at the end of the line, it's time to start working backwards so start with an empty struct to hold our condensesd metadata.
			local.parent = {};
			local.parent.inheritancetrail = [];
		}

		for( local.key in arguments.md ){
			//Functions and properties are an array of structs keyed on name, so I can treat them the same
			if( listFindNoCase( "functions,properties", local.key ) ){
				
				// create reference
				if( NOT structKeyExists( local.parent, local.key ) ){
					local.parent[ local.key ] = [];
				}
				
				// For each function/property in me...
				for( local.item in arguments.md[ local.key ] ){
					
					local.parentItemCounter = 0;
					local.foundInParent = false;

					// ...Look for an item of the same name in my parent...
					for( local.parentItem in local.parent[ local.key ] ){
						local.parentItemCounter++;
						// ...And override it
						if( compareNoCase( local.item.name, local.parentItem.name ) eq 0 ){
							local.parent[ local.key ][ local.parentItemCounter ] = local.item;
							local.foundInParent = true;
							break;
						}
					}

					// ...Or just add it
					if( not local.foundInParent ){
						arrayAppend( local.parent[ local.key ], local.item );
					}
				}
			} else if( NOT listFindNoCase( "extends,implements", local.key ) ){
				local.parent[ local.key ] = arguments.md[ local.key ];
			}
		}

		arrayPrePend( local.parent.inheritanceTrail, local.parent.name );
		
		return local.parent;
	}

}