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
	
	property name='cbClient' inject='CouchbaseClient';

	
	// Save yourself!		
	function save() {
		return cbClient.set( getBeerID(), this );
	}	


}