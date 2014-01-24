/**
* My Event Handler Hint
*/
component{
	
	property name="couchbase" inject="Client@couchbase";

	// Index
	any function index( event, rc, prc ){
		prc.beers = couchbase.query( 'beer', 'brewery_beers', { limit: 25, includeDocs: true } );
	}
	
}