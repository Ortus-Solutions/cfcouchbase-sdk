<cfoutput>
	<cfset endRecord = min(url.startRecord+url.recordsPerPage-1,attributes.totalRecords)>
	<cfset nextStartRecord = url.startRecord+url.recordsPerPage>
	<cfset prevStartRecord = max(url.startRecord-url.recordsPerPage,1)>
	
	Viewing #url.startRecord# - #endRecord# of #attributes.totalRecords#<br>
	
	<cfif url.startRecord GT 1>
		<a href="?recordsPerPage=#url.recordsPerPage#&startRecord=#prevStartRecord#">Prev</a>
	<cfelse>
		Prev
	</cfif>
	<select name="recordsPerPage" id="recordsPerPage" onChange="document.location.href='?recordsPerPage=' + this.options[this.selectedIndex].value +  '&startRecord=#url.startRecord#';">
		<cfloop array="#[5,10,50,100,500]#" index="i">
			<option value="#i#"<cfif i eq url.recordsPerPage> selected=true</cfif>>#i# per page</option>
		</cfloop>
	</select>
	<cfif endRecord LT attributes.totalRecords>
		<a href="?recordsPerPage=#url.recordsPerPage#&startRecord=#nextStartRecord#">Next</a>
	<cfelse>
		Next
	</cfif>
</cfoutput>