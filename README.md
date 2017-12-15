# PowerShell-BrowserData-Parsers
A collection of cmdlets used to enumerate browser data. Credit [@424f424f] for a fair amount of code snippets, particularly the Regex for the Scrape functions.

## Get-FirefoxData 
Contains three functions: Get-FirefoxHistory, Get-FirefoxBookmarks, and Scrape-FirefoxHistory. Both Get-FirefoxHistory and Get-FirefoxBookmarks requires the PSSQLite module, which is located in the PowerShell gallery, or at https://github.com/RamblingCookieMonster/PSSQLite.

### Get-FirefoxHistory
Uses PSSQLite to query the places.sqlite file to extract browser history. 

### Get-FirefoxBookmarks
Uses PSSQLite to query the places.sqlite file to extract browser bookmarks.

### Scrape-FirefoxHistory
Uses a Regex to scrape URLs from the places.sqlite file. Use this function if you can't install PSSQLite.

## Get-InternetExplorerData
Contains three functions: Get-InternetExplorerHistory, Get-InternetExplorerBookmarks, and Get-WebCacheV01URLs. Get-WebCacheV01URLs requires the ESENT module, which can be found in the PowerShell gallery.


