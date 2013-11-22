<cfparam name="url.version" default="1.0.0">
<cfscript>
	colddoc = new ColdDoc();

	strategy = new colddoc.strategy.api.HTMLAPIStrategy( expandPath("./docs"), "CFCouchbase SDK #url.version#" );
	colddoc.setStrategy( strategy );

	colddoc.generate( expandPath("/cfcouchbase"), "cfcouchbase" );
</cfscript>

<h1>Done!</h1>

<a href="docs">Documentation</a>
