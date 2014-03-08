<cfoutput>		
	<h1>Beer Brewery Manager</h1>
	<h3>#numberFormat( prc.numBeers )# beers across #numberFormat( prc.numBreweries )# breweries</h3>

	<cfset rc.totalRecords = prc.numBreweries>
	#renderView( 'paginationOptions' )#
	
	<cfloop array="#prc.breweries#" index="breweryRow">
		<cfset brewery = breweryRow.document>
		
		<h4>
			<a href="#event.buildLink( linkTo="brewery.view", queryString="breweryID=#brewery.getBreweryID()#" )#">
				#HTMLEditFormat(brewery.getName())#
			</a>
			(#brewery.getBeerCount()# Beers)
		</h4>
		<cfif len(brewery.getWebsite())>
		#brewery.getState()#, 
		</cfif>
		#brewery.getCountry()#<br>
		<cfif len( brewery.getWebsite() )>
			<a href="#brewery.getWebsite()#">website</a><br>
		</cfif>
		
		<small>#HTMLEditFormat(brewery.getDescription())#</small>
		
	</cfloop>
	
</cfoutput>