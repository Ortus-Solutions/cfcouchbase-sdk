<cfoutput>
	<h1>Beer Brewery Manager</h1>
	
	<cfparam name="url.recordsPerPage" default="5" type="numeric" min="1">
	<cfparam name="url.startRecord" default="1" type="numeric" min="1">
	
	<cfset cbClient = application.couchbase>
	<cfset breweryCount = cbClient.query("manager", "listBreweries")>
	<cfset breweries = cbClient.query("manager", "listBreweries", { includeDocs = true, limit=url.recordsPerPage, offSet = url.startRecord-1, reduce = false })>

	<cfmodule template="includes/paginationOptions.cfm" totalRecords="#breweryCount[1].value#">
	
	<cfloop array="#breweries#" index="brewery">
		<cfset bDoc = brewery.document>
		<h3><a href="brewery.cfm?breweryID=#brewery.id#">#HTMLEditFormat(bDoc.name)#</a></h3>
		#bDoc.state#, #bDoc.country#<br>
		<a href="#bDoc.website#">website</a><br>
		
		<small>#HTMLEditFormat(bDoc.description)#</small>
		
	</cfloop>
	
	

</cfoutput>