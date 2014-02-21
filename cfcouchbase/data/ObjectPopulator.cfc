/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>This is an object populator that binds different types of data to an object.</p>
* @author Luis Majano, Brad Wood
*/
component hint="This is an object populator that binds different types of data to a object." {

// ------------------------------------------- CONSTRUCTOR -----------------------------------------

    public ObjectPopulator function init() {
		return this;
    }

// ------------------------------------------- PUBLIC ------------------------------------------

	/**
	* Populate a named or instantiated bean from a json string
	* @target.hint The target to populate
	* @JSONString.hint The JSON string to populate the object with. It has to be valid JSON and also a structure with name-key value pairs.
	* @scope.hint Use scope injection instead of setters population. Ex: scope=variables.instance
	* @trustedSetter.hint If set to true, the setter method will be called even if it does not exist in the bean
	* @include.hint A list of keys to include in the population
	* @exclude.hint A list of keys to exclude in the population
	* @ignoreEmpty.hint Ignore empty values on populations, great for ORM population"
	* @nullEmptyInclude.hint A list of keys to NULL when empty
	* @nullEmptyExclude.hint A list of keys to NOT NULL when empty
	* @composeRelationships.hint Automatically attempt to compose relationships from memento
	* 
	* @return The populated target
	*/
	public any function populateFromJSON( 
		required any target,
		required string JSONString,
		string scope='',
		boolean trustedSetter=false,
		string include='',
		string exclude='',
		boolean ignoreEmpty=false,
		string nullEmptyInclude='',
		string nullEmptyExclude='',
		boolean composeRelationships=false
	) {
		// Inflate JSON
		arguments.memento = deserializeJSON(arguments.JSONString);

		// populate and return
		return populateFromStruct(argumentCollection=arguments);
	}

	/**
	* Populate a named or instantiated bean from an XML packet
	* @target.hint The target to populate
	* @xml.hint The XML string or packet
	* @root.hint The XML root element to start from
	* @scope.hint Use scope injection instead of setters population. Ex: scope=variables.instance
	* @trustedSetter.hint If set to true, the setter method will be called even if it does not exist in the bean
	* @include.hint A list of keys to include in the population
	* @exclude.hint A list of keys to exclude in the population
	* @ignoreEmpty.hint Ignore empty values on populations, great for ORM population"
	* @nullEmptyInclude.hint A list of keys to NULL when empty
	* @nullEmptyExclude.hint A list of keys to NOT NULL when empty
	* @composeRelationships.hint Automatically attempt to compose relationships from memento
	* 
	* @return The populated target
	*/
	public any function populateFromXML( 
		required any target,
		required any xml,
		string root,
		string scope='',
		boolean trustedSetter=false,
		string include='',
		string exclude='',
		boolean ignoreEmpty=false,
		string nullEmptyInclude='',
		string nullEmptyExclude='',
		boolean composeRelationships=false
	) { 
		var key				= "";
		var childElements 	= "";
		var	x				= 1;

		// determine XML
		if( isSimpleValue(arguments.xml) ){
			arguments.xml = xmlParse( arguments.xml );
		}

		// check root
		if( NOT len(arguments.root) ){
			arguments.root = "XMLRoot";
		}

		// check children
		if( NOT structKeyExists(arguments.xml[arguments.root],"XMLChildren") ){
			return;
		}

		// prepare memento
		arguments.memento = structnew();

		// iterate and build struct of data
		childElements = arguments.xml[arguments.root].XMLChildren;
		for(x=1; x lte arrayLen(childElements); x=x+1){
			arguments.memento[ childElements[x].XMLName ] = trim(childElements[x].XMLText);
		}

		return populateFromStruct(argumentCollection=arguments);
	}

	/**
	* Populate a named or instantiated bean from query
	* @target.hint The target to populate
	* @qry.hint The query to popluate the bean object with
	* @rowNumber.hint The query row number to use for population
	* @scope.hint Use scope injection instead of setters population. Ex: scope=variables.instance
	* @trustedSetter.hint If set to true, the setter method will be called even if it does not exist in the bean
	* @include.hint A list of keys to include in the population
	* @exclude.hint A list of keys to exclude in the population
	* @ignoreEmpty.hint Ignore empty values on populations, great for ORM population"
	* @nullEmptyInclude.hint A list of keys to NULL when empty
	* @nullEmptyExclude.hint A list of keys to NOT NULL when empty
	* @composeRelationships.hint Automatically attempt to compose relationships from memento
	* 
	* @return The populated target
	*/
	public any function populateFromQuery( 
		required any target,
		required query qry,
		Numeric rowNumber,
		string scope='',
		boolean trustedSetter=false,
		string include='',
		string exclude='',
		boolean ignoreEmpty=false,
		string nullEmptyInclude='',
		string nullEmptyExclude='',
		boolean composeRelationships=false
	) { 
		//by default to take values from first row of the query
		var row = arguments.RowNumber;
		//columns array
		var cols = listToArray(arguments.qry.columnList);
		var i   = 1;

		arguments.memento = structnew();

		//build the struct from the query row
		for(i = 1; i lte arraylen(cols); i = i + 1){
			arguments.memento[cols[i]] = arguments.qry[cols[i]][row];
		}

		//populate bean and return
		return populateFromStruct(argumentCollection=arguments);
	}

	/**
	* Populate a named or instantiated bean from query using a prefix
	* @target.hint The target to populate
	* @qry.hint The query to popluate the bean object with
	* @rowNumber.hint The query row number to use for population
	* @scope.hint Use scope injection instead of setters population. Ex: scope=variables.instance
	* @trustedSetter.hint If set to true, the setter method will be called even if it does not exist in the bean
	* @include.hint A list of keys to include in the population
	* @exclude.hint A list of keys to exclude in the population
	* @prefix.hint The prefix used to filter, Example: 'user_' would apply to the following columns: 'user_id' and 'user_name' but not 'address_id'
	* @ignoreEmpty.hint Ignore empty values on populations, great for ORM population"
	* @nullEmptyInclude.hint A list of keys to NULL when empty
	* @nullEmptyExclude.hint A list of keys to NOT NULL when empty
	* @composeRelationships.hint Automatically attempt to compose relationships from memento
	* 
	* @return The populated target
	*/
	public any function populateFromQueryWithPrefix( 
		required any target,
		required query qry,
		Numeric rowNumber,
		string scope='',
		boolean trustedSetter=false,
		string include='',
		string exclude='',
		required string prefix,
		boolean ignoreEmpty=false,
		string nullEmptyInclude='',
		string nullEmptyExclude='',
		boolean composeRelationships=false
	) { 
		// Create a struct including only those keys that match the prefix.
		//by default to take values from first row of the query
		var row 			= arguments.rowNumber;
		var cols 			= listToArray(arguments.qry.columnList);
		var i   			= 1;
		var n				= arrayLen(cols);
		var prefixLength 	= len(arguments.prefix);
		var trueColumnName 	= "";

		arguments.memento = structNew();

		//build the struct from the query row
		for(i = 1; i LTE n; i = i + 1){
			if ( left(cols[i], prefixLength) EQ arguments.prefix ) {
				trueColumnName = right(cols[i], len(cols[i]) - prefixLength);
				arguments.memento[trueColumnName] = arguments.qry[cols[i]][row];
			}
		}

		//populate bean and return
		return populateFromStruct(argumentCollection=arguments);
	}
	
	/**
	* Populate a named or instantiated bean from a struct using a prefix
	* @target.hint The target to populate
	* @memento.hint The structure to populate the object with.
	* @scope.hint Use scope injection instead of setters population. Ex: scope=variables.instance
	* @trustedSetter.hint If set to true, the setter method will be called even if it does not exist in the bean
	* @include.hint A list of keys to include in the population
	* @exclude.hint A list of keys to exclude in the population
	* @prefix.hint The prefix used to filter, Example: 'user_' would apply to the following columns: 'user_id' and 'user_name' but not 'address_id'
	* @ignoreEmpty.hint Ignore empty values on populations, great for ORM population"
	* @nullEmptyInclude.hint A list of keys to NULL when empty
	* @nullEmptyExclude.hint A list of keys to NOT NULL when empty
	* @composeRelationships.hint Automatically attempt to compose relationships from memento
	* 
	* @return The populated target
	*/
	public any function populateFromStructWithPrefix( 
		required any target,
		required struct memento,
		string scope='',
		boolean trustedSetter=false,
		string include='',
		string exclude='',
		required string prefix,
		boolean ignoreEmpty=false,
		string nullEmptyInclude='',
		string nullEmptyExclude='',
		boolean composeRelationships=false
	) { 
		var key 			= "";
		var newMemento 		= structNew();
		var prefixLength 	= len( arguments.prefix );
		var trueName		= "";

		//build the struct from the query row
		for( key in arguments.memento ){
			// only add prefixed keys
			if ( left( key, prefixLength ) EQ arguments.prefix ) {
				trueName = right( key, len( key ) - prefixLength );
				newMemento[ trueName ] = arguments.memento[ key ];
			}
		}
		
		// override memento
		arguments.memento = newMemento;
		
		//populate bean and return
		return populateFromStruct( argumentCollection=arguments );
	}
	
	
	/**
	* Populate a named or instantiated bean from a structure
	* @target.hint The target to populate
	* @memento.hint The structure to populate the object with.
	* @scope.hint Use scope injection instead of setters population. Ex: scope=variables.instance
	* @trustedSetter.hint If set to true, the setter method will be called even if it does not exist in the bean
	* @include.hint A list of keys to include in the population
	* @exclude.hint A list of keys to exclude in the population
	* @ignoreEmpty.hint Ignore empty values on populations, great for ORM population"
	* @nullEmptyInclude.hint A list of keys to NULL when empty
	* @nullEmptyExclude.hint A list of keys to NOT NULL when empty
	* @composeRelationships.hint Automatically attempt to compose relationships from memento
	* 
	* @return The populated target
	*/
	public any function populateFromStruct( 
		required any target,
		required struct memento,
		string scope='',
		boolean trustedSetter=false,
		string include='',
		string exclude='',
		boolean ignoreEmpty=false,
		string nullEmptyInclude='',
		string nullEmptyExclude='',
		boolean composeRelationships=false
	) { 
		var beanInstance = arguments.target;
		var key = "";
		var pop = true;
		var scopeInjection = false;
		var udfCall = "";
		var args = "";
		var nullValue = false;
		var propertyValue = "";
		var relationalMeta = "";

		try{

			// Determine Method of population
			if( structKeyExists(arguments,"scope") and len(trim(arguments.scope)) neq 0 ){
				scopeInjection = true;
				// Add mixin to target
				beanInstance.populatePropertyMixin = variables.populatePropertyMixin;
			}

			// If composing relationships, get target metadata
			if( arguments.composeRelationships ) {
				relationalMeta = getRelationshipMetaData( arguments.target );
			}

			// Populate Bean
			for(key in arguments.memento){
				// shortcut to property value
				propertyValue = arguments.memento[ key ];
				
				// init population flag
				pop = true;
				// init nullValue flag
				nullValue = false;
				// Include List?
				if( len(arguments.include) AND NOT listFindNoCase(arguments.include,key) ){
					pop = false;
				}
				// Exclude List?
				if( len(arguments.exclude) AND listFindNoCase(arguments.exclude,key) ){
					pop = false;
				}
				// Ignore Empty?
				if( arguments.ignoreEmpty and isSimpleValue(propertyValue) and not len( trim( propertyValue ) ) ){
					pop = false;
				}

				// Pop?
				if( pop ){
					// Scope Injection?
					if( scopeInjection ){
						beanInstance.populatePropertyMixin(propertyName=key,propertyValue=propertyValue,scope=arguments.scope);
					}
					// Check if setter exists, evaluate is used, so it can call on java/groovy objects
					else if( structKeyExists( beanInstance, "set" & key ) or arguments.trustedSetter ){
						// top-level null settings
						if( arguments.nullEmptyInclude == "*" ) {
							nullValue = true;
						}
						if( arguments.nullEmptyExclude == "*" ) {
							nullValue = false;
						}
						// Is property in empty-to-null include list?
						if( ( len( arguments.nullEmptyInclude ) && listFindNoCase( arguments.nullEmptyInclude, key ) ) ) {
							nullValue = true;
						} 
						// Is property in empty-to-null exclude list, or is exclude list "*"?
						if( ( len( arguments.nullEmptyExclude ) AND listFindNoCase( arguments.nullEmptyExclude, key ) ) ){
							nullValue = false;
						}
						// Is value nullable (e.g., simple, empty string)? If so, set null...
						if( isSimpleValue( propertyValue ) && !len( trim( propertyValue ) ) && nullValue ) {
							propertyValue = JavaCast( "null", "" );
						}

						// If property isn't null, try to compose the relationship
						if( !isNull( propertyValue ) && composeRelationships && structKeyExists( relationalMeta, key ) ) {
							// get valid, known entity name list
							var validEntityNames = structKeyList( ORMGetSessionFactory().getAllClassMetadata() );
							var targetEntityName = "";
							/**
							 * The only info we know about the relationships are the property names and the cfcs
							 * CFC setting can be relative, so can't assume that component lookup will work
							 * APPROACH
							 * 1.) Easy: If property name of relationship is a valid entity name, use that
							 * 2.) Harder: If property name is not a valid entity name (e.g., one-to-many, many-to-many), use cfc name
							 * 3.) Nuclear: If neither above works, try by component meta data lookup. Won't work if using relative paths!!!!
							 */

							// 1.) name match
							if( listFindNoCase( validEntityNames, key ) ) {
								targetEntityName = key;
							}
							// 2.) attempt match on CFC metadata
							else if( listFindNoCase( validEntityNames, listLast( relationalMeta[ key ].cfc, "." ) ) ) {
								targetEntityName = listLast( relationalMeta[ key ].cfc, "." );
							}
							// 3.) component lookup
							else {
								try {
									targetEntityName = getComponentMetaData( relationalMeta[ key ].cfc ).entityName;
								}
								catch( any e ) {
									throw(type="BeanPopulator.PopulateBeanException",
						  			  message="Error populating bean #getMetaData(beanInstance).name# relationship of #key#. The component #relationalMeta[ key ].cfc# could not be found.",
						  			  detail="#e.Detail#<br>#e.message#<br>#e.tagContext.toString()#");
								}
								
							}
							// if targetEntityName was successfully found
							if( len( targetEntityName) ) {
								// array or struct type (one-to-many, many-to-many)
								if( listContainsNoCase( "one-to-many,many-to-many", relationalMeta[ key ].fieldtype ) ) {
									// Support straight-up lists and convert to array
									if( isSimpleValue( propertyValue ) ) {
										propertyValue = listToArray( propertyValue );
									}
									var relType = structKeyExists( relationalMeta[ key ], "type" ) && relationalMeta[ key ].type != "any" ? relationalMeta[ key ].type : 'array';
									var manyMap = reltype=="struct" ? {} : [];
									// loop over array
									for( var relValue in propertyValue ) {
										// for type of array
										if( relType=="array" ) {
											// add composed relationship to array
											arrayAppend( manyMap, EntityLoadByPK( targetEntityName, relValue ) );
										}
										// for type of struct
										else {
											// make sure structKeyColumn is defined in meta
											if( structKeyExists( relationalMeta[ key ], "structKeyColumn" ) ) {
												// load the value
												var item = EntityLoadByPK( targetEntityName, relValue );
												var structKeyColumn = relationalMeta[ key ].structKeyColumn;
												var keyValue = "";
												// try to get struct key value from entity
												if( !isNull( item ) ) {
													try {
														keyValue = evaluate("item.get#structKeyColumn#()");
													}
													catch( Any e ) {
														throw(type="BeanPopulator.PopulateBeanException",
                							  			  message="Error populating bean #getMetaData(beanInstance).name# relationship of #key#. The structKeyColumn #structKeyColumn# could not be resolved.",
                							  			  detail="#e.Detail#<br>#e.message#<br>#e.tagContext.toString()#");
													}
												}
												// if the structKeyColumn value was found...
												if( len( keyValue ) ) {
													manyMap[ keyValue ] = item;
												}
											}
										}
									}
									// set main property value to the full array of entities
									propertyValue = manyMap;
								}
								// otherwise, simple value; load relationship (one-to-one, many-to-one)
								else {
									if( isSimpleValue( propertyValue ) && trim( propertyValue ) != "" ) {
										propertyValue = EntityLoadByPK( targetEntityName, propertyValue );
									}
								}	
							} // if target entity name found
						}
						// Populate the property as a null value
						if( isNull( propertyValue ) ) {
							// Finally...set the value
							evaluate( "beanInstance.set#key#( JavaCast( 'null', '' ) )" );
						}
						// Populate the property as the value obtained whether simple or related
						else {
							evaluate( "beanInstance.set#key#( propertyValue )" );
						}
						
					} // end if setter or scope injection
				}// end if prop ignored

			}//end for loop
			return beanInstance;
		}
		catch( Any e ){
			if( isNull( propertyValue ) ) {
				arguments.keyTypeAsString = "NULL";
			}
			else if ( isObject( propertyValue ) OR isCustomFunction( propertyValue )){
				arguments.keyTypeAsString = getMetaData( propertyValue ).name;
			}
			else{
	        	arguments.keyTypeAsString = propertyValue.getClass().toString();
			}
			throw(type="BeanPopulator.PopulateBeanException",
				  			  message="Error populating bean #getMetaData(beanInstance).name# with argument #key# of type #arguments.keyTypeAsString#.",
				  			  detail="#e.Detail#<br>#e.message#<br>#e.tagContext.toString()#");
		}
	}

	// ------------------------------------------- PRIVATE ------------------------------------------
	
	/**
	* Prepares a structure of target relational meta data
	* @target.hint The target object
	*
	* @return A struct of metadata about the target's relationships
	*/
	private struct function getRelationshipMetaData( required any target ) {
		var meta = {};
		// get array of properties
		var properties = getMetaData( arguments.target ).properties;
		// loop over properties
		for( var i = 1; i <= arrayLen( properties ); i++ ) {
			var property = properties[ i ];
			// if property has a name, a fieldtype, and is not the ID, add to maps
			if( structKeyExists( property, "fieldtype" ) && 
				structKeyExists( property, "name" ) && 
				!listFindNoCase( "id,column", property.fieldtype ) ) {
				meta[ property.name ] = property;
			}
		}
		return meta;
	}

	/**
	* Populates a property if it exists
	* @propertyName.hint The name of the property to inject.
	* @propertyValue.hint The value of the property to inject
	* @scope.hint The scope to which inject the property to.
	*/
	private function populatePropertyMixin( required propertyName, required propertyValue, scope='variables' ) {
		// Validate Property
		if( structKeyExists(evaluate(arguments.scope),arguments.propertyName) ){
			"#arguments.scope#.#arguments.propertyName#" = arguments.propertyValue;
		}
	}

}