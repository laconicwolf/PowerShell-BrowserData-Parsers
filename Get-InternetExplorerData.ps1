Function Get-InternetExplorerBookmarks {
    <#
    .SYNOPSIS
        Returns the Internet Explorer bookmark entries
        Author: Jake Miller (@LaconicWolf) 
        Referenced: https://github.com/rvrsh3ll/Misc-Powershell-Scripts/blob/master/Get-BrowserData.ps1
        Required Dependencies: None
    .DESCRIPTION
        Queries the Internet Explorer favorites folder to gather bookmark information.
    .PARAMETER UserName
        Specifies which User's favorites will be queried. Defaults
        to $env:USERNAME.
    .EXAMPLE
        PS C:\> Get-InternetExplorerBookmarks
        Will return all HTTP/HTTPS bookmarks.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        $UserName = $env:USERNAME
    )

    $favorites = Get-ChildItem -Path "$Env:SystemDrive\Users\$UserName\Favorites\" -Filter "*.url" -Recurse -ErrorAction SilentlyContinue
    foreach ($favorite in $favorites) {
        Get-Content -Path $favorite.FullName | ForEach-Object {
            if ($_.Startswith('URL')) {
                $url = $_.Substring($_.IndexOf('=') + 1)
                New-Object -TypeName PSObject -Property @{URL = $url}
            }
        }
    }
}

Function Get-WebCacheV01URLs {
    <#
    .SYNOPSIS
        Returns the URLs contained within the WebCacheV01.dat ESE database.
        Author: Jake Miller (@LaconicWolf) 
        Required Dependencies: ESENT
        Requires Administrative Privileges to stop services that lock the data file.
        WARNING: Do not use this for forensics purposes, as it seems to alter the
        database.
    .DESCRIPTION
        Queries the WebCacheV01.dat file to gather URL history information.
        When no options are specified the database is printed. A variety of 
        options can be specified via the parameters. Additionally, the Query 
        parameter can be used to return customized results.
    .PARAMETER UserName
        Specifies which User's WebCacheV01.dat file will be queried. Defaults
        to $env:USERNAME.
    .PARAMETER Search
        Specifies a string to search for in the URL and querystring.
    .PARAMETER Query
        Allows for custom queries against the WebCacheV01.dat file.
        the n most visited URLs along with their visit count.
    .PARAMETER AllUrls
        Returns all URLs in the file             
    .EXAMPLE
        PS C:\> Get-WebCacheV01URLs -AllUrls
        Gathers all URLs in the file. Some of these URLs also seem to be
        non-user browsing related, so this may return a lot of data that
        may or may not be useful.
    .EXAMPLE
        PS C:\> Get-WebCacheV01URLs -Search login
        Returns all URLs that contain 'login' in the URL/querystring.
    #>

    [CmdletBinding()]
    Param(

        [Parameter(Mandatory = $false)]
        $UserName = $env:USERNAME,

        [Parameter(Mandatory = $false)]
        $Search,

        [Parameter(Mandatory = $false)]
        [switch]
        $AllUrls,

        [Parameter(Mandatory = $false)]
        [switch]
        $Force

    )

    Import-Module ESENT

    if ( -not $Force ) {
        $Prompt = 'n'
        $Prompt = Read-Host "`nWARNING: This function will attempt to stop services 
and attempt to query the WebCachev01.dat ESE database file
This may corrupt the file. Would you like to continue? [y] or [n]. Default is [n]"
   
        if (-not ($Prompt.StartsWith('y') -or ($Prompt.StartsWith('Y')))){
            return
        }
    }

    $ESEDbPath = "C:\Users\$UserName\AppData\Local\Microsoft\Windows\WebCache\WebCacheV01.dat"
    if (-not (Test-Path -Path $ESEDbPath)){
        Write-Verbose "[*] Could not find the Internet Explorer ESE database for username: $UserName"
        return
    }

    try {
        $DB = Get-ESEDatabase -Path $ESEDbPath -LogPrefix "V01" -ProcessesToStop @("dllhost","taskhostw") -Force
    }
    catch {
        Write-Error "`nA database error occurred"
        return
    }

    if ($AllUrls) {
        $DB.Rows.url | ForEach-Object {
            if ($_ -eq $null) {
                continue
            }
            if ($_.startswith('http')) {
                $Key = $_
                New-Object -TypeName PSObject -Property @{URL = $_}
            }
        }
    }

    elseif ($Search) {
        $DB.Rows.url | ForEach-Object {
            if ($_ -eq $null) {
                continue
            }
            if ($_.startswith('http') -and $_ -match $Search) {
                $Key = $_
                New-Object -TypeName PSObject -Property @{URL = $_}
            }
        }
    }
    else {

        # If no options were specified just dump everything
        Write-Host "`nNo options specified. Dumping database.`n" -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        $DB
    }
}

function Get-InternetExplorerHistory {
    <#
    .SYNOPSIS
        Returns the Internet Explorer URL history that is explicitly typed or pasted
        into the browser. Will not include links that are clicked.
        Author: Jake Miller (@LaconicWolf) 
        Referenced: https://github.com/rvrsh3ll/Misc-Powershell-Scripts/blob/master/Get-BrowserData.ps1 who referenced https://crucialsecurityblog.harris.com/2011/03/14/typedurls-part-1/
        Required Dependencies: None
    .DESCRIPTION
        Checks the value of the TypedURLs registry key and returns each value. This key
        stores URLs that are typed or pasted into the browser. It will not include links clicked.
    .PARAMETER Search
        Specifies a string to search for in the URL and querystring.
    .PARAMETER AllUrls
        Returns all URLs in the specified in the registry key.            
    .EXAMPLE
        PS C:\> Get-InternetExplorerHistory -AllUrls
        Returns all URLs in the specified in the registry key.
    .EXAMPLE
        PS C:\> Get-InternetExplorerHistory -Search login
        Returns all URLs that contain 'login' in the URL/querystring.
    #>

    [CmdletBinding()]
    Param(

        [Parameter(Mandatory = $false)]
        $UserName = $env:USERNAME,

        [Parameter(Mandatory = $false)]
        $Search,

        [Parameter(Mandatory = $false)]
        [switch]
        $AllUrls # This parameter isn't really needed. Just there to keep consistancy with the other functions.

    )
    
    $Null = New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS
    $Paths = Get-ChildItem 'HKU:\' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+$' }

    ForEach($Path in $Paths) {

        $User = ([System.Security.Principal.SecurityIdentifier] $Path.PSChildName).Translate( [System.Security.Principal.NTAccount]) | Select -ExpandProperty Value

        $Path = $Path | Select-Object -ExpandProperty PSPath

        echo $Path

        $UserPath = "$Path\Software\Microsoft\Internet Explorer\TypedURLs"
        if (-not (Test-Path -Path $UserPath)) {
            Write-Verbose "[!] Could not find IE History for SID: $Path"
        }
        Get-Item -Path $UserPath -ErrorAction SilentlyContinue | ForEach-Object {
            $Key = $_
            $Key.GetValueNames() | ForEach-Object {
                $Value = $Key.GetValue($_)
                if ($Value -match $Search) {
                    New-Object -TypeName PSObject -Property @{ URL=$Value}
                }
            }
        }
    }
}