/**
********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
* @author Luis Majano, Brad Wood
* This is the main Couchbase SDK utility object
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
    	return ( exception.type == 'net.spy.memcached.OperationTimeoutException' || 
    			 exception.message == 'Exception waiting for value' || 
    			 exception.message == 'Interrupted waiting for value' );
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

}
