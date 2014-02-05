component {
	
	function configure(){
	
		coldbox = {
			appName 				= 'Brewery Manager',
			
			debugMode				= false,
			debugPassword			= '',
			reinitPassword			= '',
			
			defaultEvent			= 'brewery.list'
		};
		
		settings = {
			couchbaseSettings = {
				servers='http://127.0.0.1:8091',
				bucketname='beer-sample'
			}
		};
		
		interceptors = [
			 {class='coldbox.system.interceptors.SES'},
			 {class='root.model.ensureViews'}
		];
		
	}

}