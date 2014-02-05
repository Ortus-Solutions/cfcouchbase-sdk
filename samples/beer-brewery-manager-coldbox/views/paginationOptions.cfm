<cfoutput>
	<cfset endRecord = min(rc.startRecord+rc.recordsPerPage-1,rc.totalRecords)>
	<cfset nextStartRecord = rc.startRecord+rc.recordsPerPage>
	<cfset prevStartRecord = max(rc.startRecord-rc.recordsPerPage,1)>
	
	Viewing #rc.startRecord# - #endRecord# of #rc.totalRecords#<br>
	
	<cfif rc.startRecord GT 1>
		<a href="?recordsPerPage=#rc.recordsPerPage#&startRecord=#prevStartRecord#">Prev</a>
	<cfelse>
		Prev
	</cfif>
	<select name="recordsPerPage" id="recordsPerPage" onChange="document.location.href='?recordsPerPage=' + this.options[this.selectedIndex].value +  '&startRecord=#rc.startRecord#';">
		<cfloop array="#[5,10,50,100,500]#" index="i">
			<option value="#i#"<cfif i eq rc.recordsPerPage> selected=true</cfif>>#i# per page</option>
		</cfloop>
	</select>
	<cfif endRecord LT rc.totalRecords>
		<a href="?recordsPerPage=#rc.recordsPerPage#&startRecord=#nextStartRecord#">Next</a>
	<cfelse>
		Next
	</cfif>
</cfoutput>