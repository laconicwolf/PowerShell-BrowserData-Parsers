Import-Module PSSQLite

Function Get-FirefoxBookmarks {
    <#
    .SYNOPSIS
        Returns the Firefox bookmark entries
        Author: Jake Miller (@LaconicWolf) 
        Required Dependencies: PSSQLite
    .DESCRIPTION
        Queries the places.sqlite file to gather bookmark information.
    .PARAMETER UserName
        Specifies which User's places.sqlite file will be queried. Defaults
        to $env:USERNAME.
    .EXAMPLE
        PS C:\> Get-FirefoxBookmarks
        Will return all bookmarks. Note that it may include file locations,
        as well as HTTP(S)
    .EXAMPLE
        PS C:\> Get-FirefoxBookmarks | Where-Object { $_.url.startswith('http')}
        Will return all HTTP(S) bookmarks.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        $UserName = $env:USERNAME
    )

    # Build the path to the SQLite database. Uses a wildcard (*) in the 
    # path so it will work on the random-character folder name
    $SQLiteDbPath = "$env:SystemDrive\Users\$UserName\AppData\Roaming\mozilla\firefox\Profiles\*.default\places.sqlite"
    $SQLiteDbPath = (Get-ChildItem -Path $SQLiteDbPath).Directory.Name
    $SQLiteDbPath = "$env:SystemDrive\Users\$UserName\AppData\Roaming\mozilla\firefox\Profiles\$SQLiteDbPath\places.sqlite"

    if (-not (Test-Path -Path $SQLiteDbPath)){
        Write-Verbose "[*] Could not find the Firefox History SQLite database for user: $UserName"
        return
    }

    # Get the fk value from moz_bookmarks, which corresponds to 
    # the id value in moz_places
    $BookMarkIDs = Invoke-SqliteQuery -DataSource $SQLiteDbPath -Query "SELECT fk FROM moz_bookmarks WHERE fk NOT NULL"

    # Set the query to a variable so the fk/id variable can expland into the statement
    $VarQuery = "SELECT url FROM moz_places WHERE id = var"
    foreach($id in $BookMarkIDs) {
        Invoke-SqliteQuery -DataSource $SQLiteDbPath -Query $VarQuery.Replace('var', $id.fk)
    }
}


Function Get-FirefoxHistory {
    <#
    .SYNOPSIS
        Returns the Firefox URL history
        Author: Jake Miller (@LaconicWolf) 
        Required Dependencies: PSSQLite
    .DESCRIPTION
        Queries the places.sqlite file to gather URL history information.
        When no options are specified the database is printed. A variety of 
        options can be specified via the parameters. Additionally, the Query 
        parameter can be used to return customized results.
    .PARAMETER UserName
        Specifies which User's places.sqlite file will be queried. Defaults
        to $env:USERNAME.
    .PARAMETER Search
        Specifies a string to search for in the URL and querystring.
    .PARAMETER Query
        Allows for custome queries against the places.sqlite file.
    .PARAMETER NumberOfDays
        Limits returned data to match only entries greater than the 
        current date minus the number of days specified.
    .PARAMETER MostVisited
        Will sort the sites by visit count and return only 
        the n most visited URLs along with their visit count.
    .PARAMETER AllUrls
        Returns all URLs in the file
    .PARAMETER ShowColumns
        Prints the database schema so it easier to create custom queries.              
    .EXAMPLE
        PS C:\> Get-FirefoxHistory -AllUrls
        Gathers all URLs in the file. Note: This also includes the bookmarks,
        as they are in the same file
    .EXAMPLE
        PS C:\> Get-FirefoxHistory -Query "SELECT * from moz_places"
        Custom query that returns everything from the moz_places table.
    .EXAMPLE
        PS C:\> Get-FirefoxHistory -Search login
        Returns all URLs that contain 'login' in the URL/querystring
    .EXAMPLE
        PS C:\> Get-FirefoxHistory -MostVisited 10
        Returns the 10 most visited URLs and their visit counts
    #>

    [CmdletBinding()]
    Param(

        [Parameter(Mandatory = $false)]
        $UserName = $env:USERNAME,

        [Parameter(Mandatory = $false)]
        $Search,

        [Parameter(Mandatory = $false)]
        $Query,

        [Parameter(Mandatory = $false)]
        $NumberOfDays,

        [Parameter(Mandatory = $false)]
        $MostVisited,

        [Parameter(Mandatory = $false)]
        [switch]
        $AllUrls,

        [Parameter(Mandatory = $false)]
        [switch]
        $ShowColumns

    )

    # Build the path to the SQLite database. Uses a wildcard (*) in the 
    # path so it will work on the random-character folder name
    $SQLiteDbPath = "$env:SystemDrive\Users\$UserName\AppData\Roaming\mozilla\firefox\Profiles\*.default\places.sqlite"
    $SQLiteDbPath = (Get-ChildItem -Path $SQLiteDbPath).Directory.Name
    $SQLiteDbPath = "$env:SystemDrive\Users\$UserName\AppData\Roaming\mozilla\firefox\Profiles\$SQLiteDbPath\places.sqlite"

    if (-not (Test-Path -Path $SQLiteDbPath)){
        Write-Verbose "[*] Could not find the Firefox History SQLite database for user: $UserName"
        return
    }

    if ($ShowColumns) {
        Invoke-SqliteQuery -DataSource $SQLiteDbPath -Query "PRAGMA table_info(moz_places)" | Select-Object name
    }

    elseif ($AllUrls) {
        Invoke-SqliteQuery -DataSource $SQLiteDbPath -Query "SELECT url FROM moz_places"
    }

    elseif ($Search) {
        Invoke-SqliteQuery -DataSource $SQLiteDbPath -Query "SELECT url FROM moz_places WHERE url LIKE '%$Search%'"
    }

    elseif ($Query) {
        Invoke-SqliteQuery -DataSource $SQLiteDbPath -Query $Query 
    }

    elseif ($NumberOfDays) {
       
        # Convert to Epoch time
        $date1 = Get-Date -Date "01/01/1970"
        $date2 = (Get-Date).AddDays(-$NumberOfDays)
        [int]$timeLimit = (New-TimeSpan -Start $date1 -End $date2).TotalSeconds

        Invoke-SqliteQuery -DataSource $SQLiteDbPath -Query "SELECT url,last_visit_date FROM moz_places" | ForEach-Object {

            # Convert last_visit_date to string to remove trailing digits
            $strtime = [string]$_.last_visit_date
            try {

                # Removes 6 trailing digits (to match $timelimit), and converts back to int
                [int]$visitTime = $strtime.Substring(0, $strtime.Length-6)
            }

            #handles errors for null last_visit_date
            Catch {
                Continue
            }
            if ($visitTime -gt $timeLimit) {
                Write-Output $_.url
            }
        }
    }

    elseif ($MostVisited) {
        Invoke-SqliteQuery -DataSource $SQLiteDbPath -Query "SELECT * FROM moz_places" | Sort-Object -Property visit_count -Descending | Select-Object url,visit_count -First $MostVisited
    }

    else {
        # If no options were specified just dump everything
        Write-Output "`nNo options specified. Dumping database.`n"
        Start-Sleep -Seconds 3
        Invoke-SqliteQuery -DataSource $SQLiteDbPath -Query "SELECT * FROM moz_places"
    }
}
