<cfsetting showdebugoutput="false">
<cfscript>
	tb = new coldbox.system.testing.TestBox( directory={ recurse=true, mapping="test.specs" } );
	writeOutput( tb.run() );
</cfscript>