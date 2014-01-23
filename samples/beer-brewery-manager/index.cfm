<cfoutput>
	<h1>Beer Brewery Manager</h1>
	
	<cfset cbClient = application.couchbase>
	<cfset breweries = cbClient.query("manager", "listBreweries", { includeDocs = true, limit=10 })> 
	
	<cfloop array="#breweries#" index="brewery">
		<cfset bDoc = brewery.document> 
		<h3><a href="#bDoc.website#">#HTMLEditFormat(bDoc.name)#</a></h3>
		#bDoc.state#, #bDoc.country#<br>
		<small>#HTMLEditFormat(bDoc.description)#</small>
		
	</cfloop>
	
	

</cfoutput>