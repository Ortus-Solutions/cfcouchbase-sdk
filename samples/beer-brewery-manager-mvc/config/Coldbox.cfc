component {

	function configure(){

		coldbox = {
			appName 				= 'Brewery Manager',
			reinitPassword			= '',
			defaultEvent			= 'brewery.list'
		};

		settings = {
			couchbaseSettings = {
				servers='http://127.0.0.1:8091',
				bucketname='beer-sample',
        username="cfcouchbase",
        password="password"
			}
		};

		interceptors = [
			 {class='root.models.ensureViews'}
		];

	}

}
