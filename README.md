# PowerShell-BrowserData-Parsers
A collection of cmdlets used to enumerate browser data.

## Get-FirefoxData 
Contains three scripts: Get-FirefoxHistory, Get-FirefoxBookmarks, and Scrape-FirefoxHistory. Both Get-FirefoxHistory and Get-FirefoxBookmarks requires the PSSQLite module, which is located in the PowerShell gallery, or at https://github.com/RamblingCookieMonster/PSSQLite.

### Get-FirefoxHistory
Uses PSSQLite to query the places.sqlite file to obtain browser history. 
