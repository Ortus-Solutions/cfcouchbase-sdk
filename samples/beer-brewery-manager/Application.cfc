/**
********************************************************************************
Copyright 2005-2014 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************
*/
component{
	// Application properties
	this.name = hash(getCurrentTemplatePath());
	this.sessionManagement = true;
	this.sessionTimeout = createTimeSpan(0,0,30,0);
	this.setClientCookies = true;
	
	// application start
	public boolean function onApplicationStart(){
		return true;
	}

	// request start
	public boolean function onRequestStart(String targetPage){
		return true;

	}
	
}