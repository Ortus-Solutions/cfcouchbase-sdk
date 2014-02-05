<cfoutput>
	<h1>Brewery Details</h1>
	
	<a href="#event.buildLink( "brewery.list" )#">Back to Brewery List</a><br><br>
			
	<cfif isnull(prc.brewery)>
		
		Invalid BreweryID "#HTMLEditFormat(rc.breweryID)#"
	
	<cfelse>
					
		<a href="#event.buildLink( linkTo="brewery.edit", queryString="breweryID=#HTMLEditFormat( prc.brewery.getBreweryID() )#" )#">Edit this Brewery's Details</a><br><br>

		<table>
			<tr>
				<td>Name:</td>
				<td>#HTMLEditFormat( prc.brewery.getName() )#</td>
			</tr>
			<tr>
				<td>website:</td>
				<td>#HTMLEditFormat( prc.brewery.getWebsite() )#</td>
			</tr>
			<tr>
				<td>Phone:</td>
				<td>#HTMLEditFormat( prc.brewery.getPhone() )#</td>
			</tr>
			<tr>
				<td>Description:</td>
				<td>#HTMLEditFormat( prc.brewery.getDescription() )#</td>
			</tr>
			<tr>
				<td>Address 1:</td>
				<td>#HTMLEditFormat( prc.brewery.getAddress1() )#</td>
			</tr>
			<tr>
				<td>Address 2:</td>
				<td>#HTMLEditFormat( prc.brewery.getAddress2() )#</td>
			</tr>
			<tr>
				<td>City:</td>
				<td>#HTMLEditFormat( prc.brewery.getCity() )#</td>
			</tr>
			<tr>
				<td>State:</td>
				<td>#HTMLEditFormat( prc.brewery.getState() )#</td>
			</tr>
			<tr>
				<td>Zip:</td>
				<td>#HTMLEditFormat( prc.brewery.getCode() )#</td>
			</tr>
			<tr>
				<td>Country:</td>
				<td>#HTMLEditFormat( prc.brewery.getCountry() )#</td>
			</tr>
			<tr>
				<td>Last Updated:</td>
				<td>#dateFormat( prc.brewery.getUpdated(),"full" )#</td>
			</tr>
		</table>
				
		<h2>#HTMLEditFormat( prc.brewery.getName() )#'s Beers</h2>
		#renderView( "beer/list" )#
					
	</cfif>
	
</cfoutput>
