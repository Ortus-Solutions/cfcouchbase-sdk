component output="false" singleton{

	property name="couchbase" inject="CouchbaseClient@cfcouchbase";
	property name="couchbaseCache" inject="cachebox:couchbase";

	// Default Action
	function index(event,rc,prc){
		prc.beers = couchbaseCache.getOrSet(
			'beerList',
			function() {
				return couchbase.query( 'beer', 'brewery_beers', { limit: 25, includeDocs: true} );
			},
			1
		);
		
		event.setView("main/index");
	}

}