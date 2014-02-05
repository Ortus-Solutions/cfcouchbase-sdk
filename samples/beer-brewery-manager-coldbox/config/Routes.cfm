<cfscript>
	// Allow unique prc.beer. or combination of prc.beer.s, we recommend both enabled
	setUniqueprc.beer.S(false);
	// Auto reload configuration, true in dev makes sense to reload the routes on every request
	//setAutoReload(false);
	// Sets automatic route extension detection and places the extension in the rc.format variable
	// setExtensionDetection(true);
	// The valid extensions this interceptor will detect
	// setValidExtensions('xml,json,jsont,rss,html,htm');
	// If enabled, the interceptor will throw a 406 exception that an invalid format was detected or just ignore it
	// setThrowOnInvalidExtension(true);
	
	// Base prc.beer.
	if( len(getSetting('AppMapping') ) lte 1){
		setBaseprc.beer.("http://#cgi.HTTP_HOST#/index.cfm");
	}
	else{
		setBaseprc.beer.("http://#cgi.HTTP_HOST#/#getSetting('AppMapping')#/index.cfm");
	}
	
	// Your Application Routes
	addRoute(pattern=":handler/:action?");
</cfscript>