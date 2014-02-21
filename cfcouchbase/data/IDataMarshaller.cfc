/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>This is our data marshaller interface for serializing and deserializing objects from Couchbase to CFML and vice-versa</p>
* @author Luis Majano, Brad Wood
*/
interface {

	/**
	* A method that is called by the couchbase client upon creation so if the marshaller implemnts this function, it can talk back to the client.
	* It must return back itself.
	*/
	any function setCouchbaseClient( required couchcbaseClient );

	/**
	* This method deserializes an incoming data string via JSON and according to our rules. It can also accept an optional 
	* inflateTo parameter wich can be an object we should inflate our data to.
	* @ID.hint The ID of the document being deserialized
	* @data.hint A JSON document to deserialize according to our rules
	* @inflateTo.hint The object that will be used to inflate the data with according to our conventions
	* @deserializeOptions.hint A struct of options to help control how the data is deserialized when populating an object
	*/
	any function deserializeData( required string ID, required string data, any inflateTo="", struct deserializeOptions={} );

	/**
	* This method serializes incoming data according to our rules and it returns a string representation usually JSON
	* @data.hint The data to serialize
	*/
	string function serializeData( required any data );


}