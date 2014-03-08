component{
	property name='breweryService' inject='breweryService';
	
	function list(event,rc,prc){
		
		event.paramValue( name='recordsPerPage', value=5 );
		event.paramValue( name='startRecord', value=1); 
		
		prc.breweries = breweryService.getBreweries( offset=rc.startRecord-1, limit=rc.recordsPerPage );
		prc.numBreweries = breweryService.getBreweryCount();
		prc.numBeers = breweryService.getBeerCount();
	}

	function view(event,rc,prc){
		event.paramValue( name='breweryID', value='not_supplied' );		
		prc.brewery = BreweryService.getBrewery( rc.breweryID );
		prc.breweryBeers = prc.brewery.getBeers();
	}

	function edit(event,rc,prc){
		event.paramValue( name='breweryID', value='not_supplied' );		
		prc.brewery = BreweryService.getBrewery( rc.breweryID );
	}

	function update(event,rc,prc){
		event.paramValue( name='breweryID', value='not_supplied' );
		var brewery = BreweryService.getBrewery( rc.breweryID );
		if( !isnull(brewery) ){
			
			// Save some typing
			for( var field in listToArray( 'name,website,phone,description,city,state,code,country,address1,address2' ) ) {
				evaluate( "brewery.set#field#( form[field] )" );
			}				
			brewery.setUpdated( "#dateFormat(now(),"yyyy-mm-dd")# #timeFormat(now(),"HH:mm:ss")#" );			
			brewery.save();			
		}
		
		setNextEvent( event="brewery.view", queryString="breweryID=#HTMLEditFormat( rc.breweryID )#" );
		
	}


	
}
