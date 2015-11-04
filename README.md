[![Hex.pm](https://img.shields.io/hexpm/l/plug.svg)](http://www.apache.org/licenses/LICENSE-2.0) [![Project Status](https://stillmaintained.com/bentonam/cfcouchbase-sdk.png)](https://stillmaintained.com/bentonam/cfcouchbase-sdk) [![TestBox](https://img.shields.io/badge/tested_with-TestBox-blue.svg)](http://wiki.coldbox.org/wiki/TestBox.cfm)

	      __       __________________                 __    __                  
	  ____\ \     / ____/ ____/ ____/___  __  _______/ /_  / /_  ____ _________ 
	 /____/\ \   / /   / /_  / /   / __ \/ / / / ___/ __ \/ __ \/ __ `/ ___/ _ \
	/____/ / /  / /___/ __/ / /___/ /_/ / /_/ / /__/ / / / /_/ / /_/ (__  )  __/
	      /_/   \____/_/    \____/\____/\__,_/\___/_/ /_/_.___/\__,_/____/\___/ 
	                                                                            
	                                                                                                                                                                                                                                                                       
SDK v2.0.0+@build.number@

WELCOME TO THE CFCOUCHBASE SDK

Copyright Since 2013 Ortus Solutions, Corp

Initially sponsored by Guardly, Inc ([www.guardly.com](http://www.guardly.com))

Couchbase is copyright and a registered trademark by Couchbase, Inc.

[www.ortussolutions.com](http://www.ortussolutions.com) | [www.couchbase.com](http://www.couchbase.com)

---

###VERSIONING

CFCouchbase SDK is maintained under the Semantic Versioning guidelines as much as possible.

Releases will be numbered with the following format:

`<major>.<minor>.<patch>+<build.number>`

And constructed with the following guidelines:

* Breaking backward compatibility bumps the major (and resets the minor and patch)
* New additions without breaking backward compatibility bumps the minor (and resets the patch)
* Bug fixes and misc changes bumps the patch

---

###LICENSE

This software is open source and bound to the Apache License, Version 2.0. If you use it,
please try to make mention of it in your code or web site.

---

### OPEN SOURCE INITIATIVE APPROVED

This software is Open Source Initiative approved Open Source Software.
Open Source Initiative Approved is a trademark of the Open Source Initiative.

---

###IMPORTANT LINKS


- Source Code - [https://github.com/Ortus-Solutions/cfcouchbase-sdk](https://github.com/Ortus-Solutions/cfcouchbase-sdk)
- Tracker Site (Bug Tracking, Issues) - [https://ortussolutions.atlassian.net/browse/COUCHBASESDK](https://ortussolutions.atlassian.net/browse/COUCHBASESDK)
- Documentation - [http://www.ortussolutions.com/docs/cfcouchbase/v1.0.0/index.html](http://www.ortussolutions.com/docs/cfcouchbase/v1.0.0/index.html)
- Blog - [http://www.ortussolutions.com/blog](http://www.ortussolutions.com/blog)
- Official Site - [http://www.ortussolutions.com/products/cfcouchbase](http://www.ortussolutions.com/products/cfcouchbase)

---

### INSTALLATION

Place anywhere in your server and create a "/cfcouchbase" mapping to the
"cfcouchbase" directory from the distribution.

```
this.mappings[ "/cfcouchbase" ] = path.to.cfcouchbase;
```

You can also place the "cfcouchbase" folder in your webroot.

---

### SYSTEM REQUIREMENTS

- Couchbase Server 1.8+
- Railo 3.1+
- Adobe ColdFusion 9.01+

---

###THE DAILY BREAD

> "Therefore let us stop passing judgment on one another. Instead, make up your mind not to put any stumbling block or obstacle in the way of a brother or sister." <cite>Romans 14:13</cite>
