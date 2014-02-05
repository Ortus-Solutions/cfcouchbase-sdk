component {
	property name='cbClient' inject='CouchbaseClient';

	function afterAspectsLoad() {
		
		// Specify the views the applications needs here.  They will be created/updated
		// when the app is initialized if they don't already exist.
		
		cbClient.asyncSaveView(
			'manager',
			'listBreweries',
			'function (doc, meta) {
			  if ( doc.type == ''brewery'' ) {
			    emit(doc.name, null);
			  }
			}',
			'_count'
		);
				
		cbClient.saveView(
			'manager',
			'listBeersByBrewery',
			'function (doc, meta) {
			  if ( doc.type == ''beer'' ) {
			    emit(doc.brewery_id, null);
			  }
			}',
			'_count'
		);
	}

}