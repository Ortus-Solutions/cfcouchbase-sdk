<cfoutput>	
	<cfparam name="url.recordsPerPage" default="5" type="numeric" min="1">
	<cfparam name="url.startRecord" default="1" type="numeric" min="1">
	
	<cfset cbClient = application.couchbase>
			
	<cfset breweryCount = cbClient.query("manager", "listBreweries")>
	<cfset BeerCount = cbClient.query("manager", "listBeersByBrewery")>
	<cfset breweries = cbClient.query(
		designDocumentName = "manager",
		viewName = "listBreweries",
		inflateTo = 'root.model.brewery',
		options = {
			includeDocs = true,
			limit=url.recordsPerPage,
			offSet = url.startRecord-1,
			reduce = false
		})>

	<cfset numBreweries = breweryCount[1].value>
	<cfset numBeers = BeerCount[1].value>

	<h1>Beer Brewery Manager</h1>
	<h3>#numberFormat(numBeers)# beers across #numberFormat(numBreweries)# breweries</h3>

	<cfmodule template="includes/paginationOptions.cfm" totalRecords="#breweryCount[1].value#">
	
	<cfloop array="#breweries#" index="brewery">
		<cfset oBrewery = brewery.document>
		<cfset numBreweryBeers = oBrewery.getBeerCount()>
		
		<h4><a href="brewery.cfm?breweryID=#brewery.id#">#HTMLEditFormat(oBrewery.getName())#</a> (#numBreweryBeers# Beers)</h4>
		<cfif len(oBrewery.getWebsite())>
		#oBrewery.getState()#, 
		</cfif>
		#oBrewery.getCountry()#<br>
		<cfif len(oBrewery.getWebsite())>
			<a href="#oBrewery.getWebsite()#">website</a><br>
		</cfif>
		
		<small>#HTMLEditFormat(oBrewery.getDescription())#</small>
		
	</cfloop>
	
</cfoutput>