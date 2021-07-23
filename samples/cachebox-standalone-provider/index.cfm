<cfoutput>	
	<cfset cache = application.cachebox.getCache( "couchbase" )>
	<cfdump var="#cache.getOrSet(
			'cacheData',
			function() {
				return 'This data was created at #now()#';
			},
			1
		)#">
		<cfabort>
	
</cfoutput>