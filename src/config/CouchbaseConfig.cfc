/**
********************************************************************************
* Copyright Since 2005 Ortus Solutions, Corp
* www.coldbox.org | www.luismajano.com | www.ortussolutions.com | www.gocontentbox.org
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALING
* IN THE SOFTWARE.
********************************************************************************
* @author Luis Majano, Brad Wood
* The Couchbase Configuration Object
*/
component accessors="true"{

	//****************************************************************************************
	// Coucbhase Configuration Properties
	//****************************************************************************************

	/**
	* The list of servers to connect to
	*/
	property name="servers"						default="http://127.0.0.1:8091";
	/**
	* The bucketname to connect to
	*/
	property name="bucketName"					default="default";
	/**
	* The optional password of the bucket
	*/
	property name="password"					default="";
	/**
	* Time in millisecs for an operation to Timeout
	*/
	property name="opTimeout"					default="2500"		type="numeric";	
	/**
	* The maximum time to block waiting for op queue operations to complete, in milliseconds.	
	*/
	property name="opQueueMaxBlockTime"			default="10000"		type="numeric";
	/**
	* Number of operations to timeout before the node is deemed down	
	*/
	property name="timeoutExceptionThreshold"	default="998"		type="numeric";
	/**
	* Read Buffer Size	
	*/
	property name="readBufferSize"				default="16384"		type="numeric";
	/**
	* Optimize behavior for the network	
	*/
	property name="shouldOptimize"				default="false" 	type="boolean";
	/**
	* Maximum number of milliseconds to wait between reconnect attempts.	
	*/
	property name="maxReconnectDelay"			default="30000"		type="numeric";
	/**
	* Wait for the specified interval before the Observe operation polls the nodes.	
	*/
	property name="obsPollInterval"				default="400"		type="numeric";
	/**
	* The maximum times to poll the master and replica(s) to meet the desired durability requirements.	
	*/
	property name="obsPollMax"					default="10"		type="numeric";
	/**
	* Time in millisecs for a view operation to Timeout
	*/
	property name="viewTimeout"					default="75000"		type="numeric";
	/**
	* Ignore Couchbase timeouts on operations, if false, then exceptions are thrown
	*/
	property name="ignoreTimeouts"				default="true"		type="boolean";
	/**
	* By default we class load all the Couchbase SDK, if false, then the SDK library must be in the servlet library path
	*/
	property name="useClassLoader"				default="true"		type="boolean";
	/**
	* The default timeout of records sent to Couchbase for storage in minutes. 0 means persist forever.
	*/
	property name="defaultTimeout"				default="0"		type="numeric";

	// Default params, just in case using cf9
	variables.servers 						= "http://127.0.0.1:8091";
	variables.bucketname 					= "default";
	variables.password 						= "";
	variables.opTimeout 					= 2500;
	variables.timeoutExceptionThreshold 	= 998;
	variables.readBufferSize				= 16384;
	variables.opQueueMaxBlockTime 			= 16384;
	variables.shouldOptimize 				= false;
	variables.maxReconnectDelay 			= 30000;
	variables.obsPollInterval 				= 400;
	variables.obsPollMax 					= 10;
	variables.viewTimeout					= 75000;
	variables.ignoreTimeouts				= true;
	variables.useClassLoader				= true;
	variables.defaultTimeout				= 0;

	/**
	* Constructor
	* You can pass any name-value pair as arguments to the constructor that matches the properties in this configuration object to be set.
	*/
	function init(){
		
		// Check incoming arguments
		for( var thisArg in arguments ){
			if( structKeyExists( arguments, thisArg ) ){
				variables[ thisArg ] = arguments[ thisArg ];
			}
		}

		return this;
	}

	/**
	* Get a memento representation of the config options
	*/
	function getMemento(){
		var results = {};

		for( var thisProp in variables ){
			if( !isCustomFunction( variables[ thisProp ] ) and thisProp neq "this" ){
				results[ thisProp ] = variables[ thisProp ];
			}
		}

		return results;
	}

}