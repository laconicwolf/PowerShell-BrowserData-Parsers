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

### Get-InternetExplorerHistory
Extracts URLs from the TypedURLs registry key. Note: This will only contain URLs types or pasted into the browser. It will not include links that are clicked.

### Get-InternetExplorerBookmarks
Extracts URLs from the Favorites folder.

### Get-WebCacheV01URLs
This function uses the ESENT module to extract data from the WebCacheV01.dat file. Ideally, you should work with a copy of the file. I would not count on this as a forensically sound solution, as it seems to alter this WebCacheV01.dat and does not produce consistent results. However, it does pull out URLs that are not contained within the TypedURLs registry key.

## Get-ChromeData
Contains three functions: Get-ChromeHistory, Get-ChromeBookmarks, and Scrape-ChromeHistory. Get-ChromeHistory requires the PSSQLite module, which is located in the PowerShell gallery, or at https://github.com/RamblingCookieMonster/PSSQLite.

### Get-ChromeHistory
Uses PSSQLite to query the History sqlite file to extract browser history. 

### Get-ChromeBookmarks
Extracts browser bookmarks from the Bookmarks JSON file.

### Scrape-ChromeHistory
Uses a Regex to scrape URLs from the History file. Use this function if you can't install PSSQLite.



