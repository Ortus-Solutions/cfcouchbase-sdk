<cfoutput>	
	<cfparam name="url.recordsPerPage" default="5" type="numeric" min="1">
	<cfparam name="url.startRecord" default="1" type="numeric" min="1">
	
	<cfset cbClient = application.couchbase>
			
	<cfset breweryCount = cbClient.query("manager", "listBreweries")>
	<cfset BeerCount = cbClient.query("manager", "listBeersByBrewery")>
	<cfset breweries = cbClient.query("manager", "listBreweries", { includeDocs = true, limit=url.recordsPerPage, offSet = url.startRecord-1, reduce = false })>

	<cfset numBreweries = breweryCount[1].value>
	<cfset numBeers = BeerCount[1].value>

	<h1>Beer Brewery Manager</h1>
	<h3>#numberFormat(numBeers)# beers across #numberFormat(numBreweries)# breweries</h3>

	<cfmodule template="includes/paginationOptions.cfm" totalRecords="#breweryCount[1].value#">
	
	<cfloop array="#breweries#" index="brewery">
			
		<cfset numBreweryBeers = 0>
		<cfset breweryBeerCount = cbClient.query("manager", "listBeersByBrewery", { group = true, key = brewery.id })>
		<cfif arraylen( breweryBeerCount )>
			<cfset numBreweryBeers = breweryBeerCount[1].value>
		</cfif>
		
		<cfset bDoc = brewery.document>
		<h4><a href="brewery.cfm?breweryID=#brewery.id#">#HTMLEditFormat(bDoc.name)#</a> (#numBreweryBeers# Beers)</h4>
		<cfif len(bDoc.website)>
		#bDoc.state#, 
		</cfif>
		#bDoc.country#<br>
		<cfif len(bDoc.website)>
			<a href="#bDoc.website#">website</a><br>
		</cfif>
		
		<small>#HTMLEditFormat(bDoc.description)#</small>
		
	</cfloop>
	
</cfoutput>