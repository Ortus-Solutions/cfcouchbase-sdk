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
	* @oQuery.hint the Java query object
	*/
	function processOptions( required options, required oQuery ){
		// options
		for( var thisKey in arguments.options ){
			var thisValue = "";
			// provide some basic auto-casting.
			switch( thisKey ){
				case "limit" : case "skip" : case "offset" : {
					 
					if( !isNumeric(arguments.options[ thisKey ]) || arguments.options[ thisKey ] < 0 ) {
						throw( message='Invalid #thisKey# value of [#arguments.options[ thisKey ]#]', detail='Valid values are non-negative integers.', type='Invalid#thisKey#' );	
					}
					
					thisValue = javaCast( "int", arguments.options[ thisKey ] );
					
					if( thisKey == 'offset' ) {
						thisKey = 'skip';
					}
					
					break;
				}
				case "debug" : case "descending" : case "inclusiveEnd" : case "includeDocs" : case "reduce" : { 
					 
					if( !isBoolean(arguments.options[ thisKey ]) ) {
						throw( message='Invalid #thisKey# value of [#arguments.options[ thisKey ]#]', detail='Valid values are TRUE and FALSE.', type='Invalid#thisKey#' );	
					}
					
					thisValue = javaCast( "boolean", arguments.options[ thisKey ] );
					break;
				}
				// handle grouping
				case "groupLevel" : case "group" : {
					// If reducing has been turned off for this query, then we can't group.  
					// This will prevent errors if you've temporarily disabled reducing on a grouped query.
					if( structKeyexists( arguments.options, "reduce" ) && !arguments.options.reduce ) {
						continue;
					}
					
					if( thisKey == 'group' ) { 
					 
						if( !isBoolean(arguments.options[ 'group' ]) ) {
							throw( message='Invalid group value of [#arguments.options[ 'group' ]#]', detail='Valid values are TRUE and FALSE.', type='InvalidGroup' );	
						}
						
						// If group is true and there is also a group level, skip the group option.  In addition to being redundant,
						// there is a nasty bug where if group=true comes after group_level on the REST URL, the group_level will be ignored:
						// http://www.couchbase.com/issues/browse/JCBC-386
						if( arguments.options[ 'group' ] && structKeyExists(arguments.options, 'groupLevel') ) {
							continue;
						}						
					
						thisValue = javaCast( "boolean", arguments.options[ 'group' ] );
					} else {
												 
						if( !isNumeric(arguments.options[ 'groupLevel' ]) || arguments.options[ 'groupLevel' ] < 0 ) {
							throw( message='Invalid groupLevel value of [#arguments.options[ 'groupLevel' ]#]', detail='Valid values are non-negative integers.', type='InvalidGroupLevel' );	
						}
						
						// If grouping has been turned off for this query, then skip grouplevel
						// This is to prevent undesired results if you've temporarily disabled grouping on a query with a group level  
						if( structKeyexists( arguments.options, "group" ) && !arguments.options.group ) {
							continue;
						}
					
						thisValue = javaCast( "int", arguments.options[ 'groupLevel' ] );
						
					}
					break;
				}
				// Allow sortOrder as a convenient facade for decending
				case "sortOrder" : {
					var sortOrder = arguments.options[ 'sortOrder' ]; 
					if( sortOrder == 'ASC' ) {
						thisValue = javaCast( "boolean", false );
					} else if( sortOrder == 'DESC' ) {
						thisValue = javaCast( "boolean", true );
					} else {
						throw( message='Invalid sortOrder value of [#sortOrder#]', detail='Valid values are ASC and DESC.', type='InvalidSortOrder' );
					}
					thisKey = 'descending';
					break;
				}
				// startKey & rangeStart
				case "startKey" : case "rangeStart" : {
					thisValue = serializeJSON( arguments.options[ thisKey ] );
					thisKey = 'rangeStart';
					break;
				}
				// startKey & rangeStart
				case "startKeyJSON" : case "rangeStartJSON" : {
					thisValue = arguments.options[ thisKey ];
					thisKey = 'rangeStart';
					break;
				}
				// endKey as rangeEnd
				case "endKey" : case "rangeEnd" : {
					thisValue = serializeJSON( arguments.options[ thisKey ] );
					thisKey = 'rangeEnd';
					break;
				}
				// endKey as rangeEnd
				case "endKeyJSON" : case "rangeEndJSON" : {
					thisValue = arguments.options[ thisKey ];
					thisKey = 'rangeEnd';
					break;
				}
				// Massage key and keys options
				case "key" : case "keys" : { 
					thisValue = serializeJSON( arguments.options[ thisKey ] );
					break;
				}
				case "keyJSON" : case "keysJSON" : { 
					thisValue = arguments.options[ thisKey ];
					break;
				}
				// handle stale option
				case "stale" : { 
					var oStale = variables.client.newJava( "com.couchbase.client.protocol.views.Stale" );
					var stale = arguments.options[ 'stale' ];
					
		            switch ( stale ){
		                // Force index rebuild (slowest)
		                case "FALSE":
		                    thisValue = oStale.FALSE;
		                    break;
		                // Stale data is ok (fastest)
		                case "OK":
		                    thisValue = oStale.OK;
		                    break;
		                // Stale is ok, but start asynch re-indexing now.
		                case "UPDATE_AFTER":
		                    thisValue = oStale.UPDATE_AFTER;
		                    break;
		                default:
		                    throw (message="The stale value of [#stale#] is invalid.", detail="Possible values are [FALSE, OK, UPDATE_AFTER].  Default behavior is 'OK' meaning stale data is acceptable.", type="InvalidStale");
		            }

					break;
				}
				default : { thisValue = arguments.options[ thisKey ]; }
			}
			// evaluate setting.
			evaluate( "arguments.oQuery.set#thisKey#( thisValue )" );
		} // end for loop

		return arguments.oQuery;
	}

}
