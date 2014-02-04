<cfoutput>	
	<cfparam name="url.recordsPerPage" default="5" type="numeric" min="1">
	<cfparam name="url.startRecord" default="1" type="numeric" min="1">
	
	<cfset breweries = application.breweryService.getBreweries( offset=url.startRecord-1, limit=url.recordsPerPage )>
	<cfset numBreweries = application.breweryService.getBreweryCount()>
	<cfset numBeers = application.breweryService.getBeerCount()>

	<h1>Beer Brewery Manager</h1>
	<h3>#numberFormat(numBeers)# beers across #numberFormat(numBreweries)# breweries</h3>

	<cfmodule template="includes/paginationOptions.cfm" totalRecords="#numBreweries#">
	
	<cfloop array="#breweries#" index="brewery">
		<cfset oBrewery = brewery.document>
		
		<h4><a href="brewery.cfm?breweryID=#oBrewery.getBreweryID()#">#HTMLEditFormat(oBrewery.getName())#</a> (#oBrewery.getBeerCount()# Beers)</h4>
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