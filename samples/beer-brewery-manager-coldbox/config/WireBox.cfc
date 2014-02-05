component extends='coldbox.system.ioc.config.Binder' {
	
	function configure(){
		
		map( 'CouchbaseClient' )
			.to( 'cfcouchbase.CouchbaseClient' )
			.initArg( name='config', value=getProperty('couchbaseSettings') )
			.asSingleton();
		
	}	

}