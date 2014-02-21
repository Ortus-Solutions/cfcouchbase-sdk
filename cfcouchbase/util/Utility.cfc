/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>This is the main Couchbase SDK utility object</p>
* @author Luis Majano, Brad Wood
*/
component accessors="true"{

	/**
	* Constructor
	*/
	Utility function init(){
		// Java URI class
		variables.URIClass	= createObject("java", "java.net.URI");
		
		return this;
	}

	/**
	* Verify if an exception is a timeout exception
	*/
	boolean function isTimeoutException( required any exception ){
    	return (
    		exception.type == 'net.spy.memcached.OperationTimeoutException' 
    		|| exception.message == 'Exception waiting for value' 
    		|| exception.message == 'Interrupted waiting for value' 
    		|| exception.message == 'Cancelled'
    	);
	}

	/**
	* Build out an array of Java URI classes
	* @server.hint The servers list to build
	*/
	array function buildServerURIs( required servers ){
		// setup
		local.i = 0;
		local.URIs = [];
		// cleanup and format servers
		arguments.servers = formatServers( arguments.servers );
		// Prepare list of servers
		while( ++local.i <= arrayLen( arguments.servers ) ){
			arrayAppend( local.URIs, variables.URIClass.create( arguments.servers[ local.i ] ) );					
		}
		return local.URIs;
	}

	/**
    * Format the incoming simple couchbase server URL location strings into our format, this allows for 
    * declaring simple URLs like 127.0.0.1:8091
    * @server.hint The servers list to format
    */
    array function formatServers( required servers ) {
    	var i = 0;
    	
		if( !isArray( arguments.servers ) ){
			servers = listToArray( arguments.servers );
		}
				
		// Massage server URLs to be "PROTOCOL://host:port/pools/"
		while( ++i <= arrayLen( arguments.servers ) ){
			
			// Add protocol if neccessary
			if( !findNoCase( "http", arguments.servers[ i ] ) ){
				arguments.servers[ i ] = "http://" & arguments.servers[ i ];
			}
			
			// Strip trailing slash via regex, its fast
			arguments.servers[ i ] = reReplace( arguments.servers[ i ], "/$", "");
			
			// Add directory
			if( right( arguments.servers[ i ], 6 ) != '/pools' ){
				arguments.servers[ i ] &= '/pools';
			}
			
		} // end server loop
		
		return arguments.servers;
	}


	/**
    * Normalize document ID to be lowercase and trimmed.
    * @ID.hint The ID to normalize, or an array of IDs
    */
    any function normalizeID( required any ID ) {
    	if( isSimpleValue( arguments.ID ) ) {
			return lcase( trim( arguments.ID ) );    		
    	} else {
    		var i = 1;
    		for( var locID in arguments.ID ) {
    			arguments.ID[ i ] = lcase( trim( locID ) );
    			i++;
    		}
    		return arguments.ID;
    	}
	}


	/**
    * Normalize view functions to not have any carridge returns.
    * The presence of ASCII code 13 in map or reduce functions will prevent you from 
    * being able to execute them from the Couchbase web admin.
    * @viewFunction.hint The function string to normalize
    */
    string function normalizeViewFunction( required string viewFunction ) {
		var CR = chr(13);
		var LF = chr(10);
		var CRLF = CR & LF;
		var CRLFPlaceholder = '__CRLF__';
		
		// I'm doing this in two steps since if I just remove CR's that have no LF, that would completely remove line breaks and cause syntax issues
		// but if I just replaced all CR's with LF's that would double all line breaks.  Therefore, all CR's and CRLF's will be converted to an LF.
		// Standalone LF's won't be touched.
		
		// Set CRLF's aside for a moment
		arguments.viewFunction = replace(arguments.viewFunction,CRLF,CRLFPlaceholder,'all');
		// Replace single CR's with LF's  
		arguments.viewFunction = replace(arguments.viewFunction,CR,LF,'all');
		// Put the CRLF's back as just LF's  
		arguments.viewFunction = replace(arguments.viewFunction,CRLFPlaceholder,LF,'all');
		
		return arguments.viewFunction;
	}

	/**
    * Deal with errors that came back from the cluster
    * rowErrors is an array of com.couchbase.client.protocol.views.RowError
    */
    any function handleRowErrors( message, rowErrors, type ){
    	local.detail = '';

    	// iterate and build errors
    	for( local.error in arguments.rowErrors ) {
    		local.detail &= local.error.getFrom();
    		local.detail &= local.error.getReason();
    	}
    	
    	throw( message=arguments.message, detail=local.detail, type=arguments.type );
    }

    /**
	* Returns a single-level metadata struct that includes all items inhereited from extending classes.
	*/
	struct function getInheritedMetaData( required component, md={} ){
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
