component accessors=true {
	property name='beerID' fieldType='id';
	property name='abv';
	property name='brewery_id';
	property name='category' default='';
	property name='description' default='';
	property name='ibu';
	property name='name';
	property name='srm';
	property name='style' default='';
	property name='type';
	property name='upc';
	property name='updated';	

	
	// Save yourself!
		
	function save() {
		return application.couchbase.set( getBeerID(), this );
	}	


}