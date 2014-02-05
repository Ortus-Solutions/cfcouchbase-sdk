<cfoutput>
	<h1>Beer Details</h1>
	
	<a href="#event.buildLink( "brewery.list" )#">Back to Brewery List</a><br><br>
			
	<cfif isnull(prc.beer)>
		
		Invalid beerID "#HTMLEditFormat( rc.beerID )#"
	
	<cfelse>
				
		<a href="#event.buildLink( linkTo="brewery.view", queryString="breweryID=#HTMLEditFormat( prc.beer.getBrewery_id() )#" )#">Back to Brewery Details</a><br><br>
		<a href="#event.buildLink( linkTo="beer.edit", queryString="beerID=#HTMLEditFormat( prc.beer.getBeerID() )#" )#">Edit this beer's Details</a><br><br>

		<table>
			<tr>
				<td>Name:</td>
				<td>#HTMLEditFormat( prc.beer.getName() )#</td>
			</tr>
			<tr>
				<td>Category:</td>
				<td>
					#HTMLEditFormat( prc.beer.getCategory() )#
				</td>
			</tr>
			<tr>
				<td>Style:</td>
				<td>#HTMLEditFormat( prc.beer.getStyle() )#</td>
			</tr>
			<tr>
				<td>Description:</td>
				<td>#HTMLEditFormat( prc.beer.getDescription() )#</td>
			</tr>
			<tr>
				<td title="International Bitterness Units">IBU:</td>
				<td>#HTMLEditFormat( prc.beer.getIBU() )#</td>
			</tr>
			<tr>
				<td title="Standard Reference Method">SRM:</td>
				<td>#HTMLEditFormat( prc.beer.getSRM() )#</td>
			</tr>
			<tr>
				<td>UPC:</td>
				<td>#HTMLEditFormat( prc.beer.getUPC() )#</td>
			</tr>
			<tr>
				<td>Last Updated:</td>
				<td>#dateFormat( prc.beer.getUpdated(), "full" )#</td>
			</tr>
		</table>
							
	</cfif>
	
</cfoutput>
