<cfoutput>
	<h1>Brewery Details</h1>
	
	<a href="index.cfm">Back to Brewery List</a><br><br>
	
	<cfparam name="url.breweryID" default="not_supplied"> 
	
	<cfset brewery = application.BreweryService.getBrewery( url.breweryID )>
		
	<cfif isnull(brewery)>
		
		Invalid BreweryID "#HTMLEditFormat(url.breweryID)#"
	
	<cfelse>
					
		<a href="breweryEdit.cfm?breweryID=#HTMLEditFormat( brewery.getBreweryID() )#">Edit this Brewery's Details</a><br><br>

		<table>
			<tr>
				<td>Name:</td>
				<td>#HTMLEditFormat( brewery.getName() )#</td>
			</tr>
			<tr>
				<td>website:</td>
				<td>#HTMLEditFormat( brewery.getWebsite() )#</td>
			</tr>
			<tr>
				<td>Phone:</td>
				<td>#HTMLEditFormat( brewery.getPhone() )#</td>
			</tr>
			<tr>
				<td>Description:</td>
				<td>#HTMLEditFormat( brewery.getDescription() )#</td>
			</tr>
			<tr>
				<td>Address 1:</td>
				<td>#HTMLEditFormat( brewery.getAddress1() )#</td>
			</tr>
			<tr>
				<td>Address 2:</td>
				<td>#HTMLEditFormat( brewery.getAddress2() )#</td>
			</tr>
			<tr>
				<td>City:</td>
				<td>#HTMLEditFormat( brewery.getCity() )#</td>
			</tr>
			<tr>
				<td>State:</td>
				<td>#HTMLEditFormat( brewery.getState() )#</td>
			</tr>
			<tr>
				<td>Zip:</td>
				<td>#HTMLEditFormat( brewery.getCode() )#</td>
			</tr>
			<tr>
				<td>Country:</td>
				<td>#HTMLEditFormat( brewery.getCountry() )#</td>
			</tr>
			<tr>
				<td>Last Updated:</td>
				<td>#dateFormat( brewery.getUpdated(),"full" )#</td>
			</tr>
		</table>

		<cfset breweryBeers = brewery.getBeers()>
				
		<h2>#HTMLEditFormat( brewery.getName() )#'s Beers</h2>
		<table border="1" cellpadding=5 cellspacing=0>
			<tr>
				<td></td>
				<td>Name</td>
				<td>Category</td>
				<td>Style</td>
				<td>Description</td>
			</tr>
			<cfloop array="#breweryBeers#" index="beerRow">
				<cfset beer = beerRow.document>
				<tr>
					<td><a href="beer.cfm?beerID=#beer.getBeerID()#">View</a></td>
					<td>#HTMLEditFormat( beer.getName() )#</td>
					<td>
						#HTMLEditFormat( beer.getCategory() )#
					</td>
					<td>
						#HTMLEditFormat( beer.getStyle() )#
					</td>
					<td>
						<cfif len( beer.getDescription() ) GT 50>
							<span title="#HTMLEditFormat( beer.getDescription() )#">#HTMLEditFormat( left( beer.getDescription(), 50) )#...</span>
						<cfelse>
							#HTMLEditFormat( beer.getDescription() )#
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>
					
	</cfif>
	
</cfoutput>
