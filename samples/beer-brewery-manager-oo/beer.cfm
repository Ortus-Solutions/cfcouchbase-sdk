<cfoutput>
	<h1>Beer Details</h1>
	
	<a href="index.cfm">Back to beer List</a><br><br>
	
	<cfparam name="url.beerID" default="not_supplied"> 
	
	<cfset beer = application.BreweryService.getBeer( url.beerID )>
		
	<cfif isnull(beer)>
		
		Invalid beerID "#HTMLEditFormat( url.beerID )#"
	
	<cfelse>
				
		<a href="brewery.cfm?breweryID=#HTMLEditFormat( beer.getBrewery_id() )#">Back to brewey Details</a><br><br>
		<a href="beerEdit.cfm?beerID=#HTMLEditFormat( beer.getBeerID() )#">Edit this beer's Details</a><br><br>

		<table>
			<tr>
				<td>Name:</td>
				<td>#HTMLEditFormat( beer.getName() )#</td>
			</tr>
			<tr>
				<td>Category:</td>
				<td>
					#HTMLEditFormat( beer.getCategory() )#
				</td>
			</tr>
			<tr>
				<td>Style:</td>
				<td>#HTMLEditFormat( beer.getStyle() )#</td>
			</tr>
			<tr>
				<td>Description:</td>
				<td>#HTMLEditFormat( beer.getDescription() )#</td>
			</tr>
			<tr>
				<td title="International Bitterness Units">IBU:</td>
				<td>#HTMLEditFormat( beer.getIBU() )#</td>
			</tr>
			<tr>
				<td title="Standard Reference Method">SRM:</td>
				<td>#HTMLEditFormat( beer.getSRM() )#</td>
			</tr>
			<tr>
				<td>UPC:</td>
				<td>#HTMLEditFormat( beer.getUPC() )#</td>
			</tr>
			<tr>
				<td>Last Updated:</td>
				<td>#dateFormat( beer.getUpdated(), "full" )#</td>
			</tr>
		</table>
							
	</cfif>
	
</cfoutput>
