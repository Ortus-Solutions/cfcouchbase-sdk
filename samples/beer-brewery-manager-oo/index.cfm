<cfoutput>	
	<cfparam name="url.recordsPerPage" default="5" type="numeric" min="1">
	<cfparam name="url.startRecord" default="1" type="numeric" min="1">
	
	<cfset breweries = application.breweryService.getBreweries( offset=url.startRecord-1, limit=url.recordsPerPage )>
	<cfset numBreweries = application.breweryService.getBreweryCount()>
	<cfset numBeers = application.breweryService.getBeerCount()>

	<h1>Beer Brewery Manager</h1>
	<h3>#numberFormat(numBeers)# beers across #numberFormat(numBreweries)# breweries</h3>

	<cfmodule template="includes/paginationOptions.cfm" totalRecords="#numBreweries#">
	
	<cfloop array="#breweries#" index="breweryRow">
		<cfset brewery = breweryRow.document>
		
		<h4><a href="brewery.cfm?breweryID=#brewery.getBreweryID()#">#HTMLEditFormat(brewery.getName())#</a> (#brewery.getBeerCount()# Beers)</h4>
		<cfif len(brewery.getWebsite())>
		#brewery.getState()#, 
		</cfif>
		#brewery.getCountry()#<br>
		<cfif len(brewery.getWebsite())>
			<a href="#brewery.getWebsite()#">website</a><br>
		</cfif>
		
		<small>#HTMLEditFormat(brewery.getDescription())#</small>
		
	</cfloop>
	
</cfoutput>