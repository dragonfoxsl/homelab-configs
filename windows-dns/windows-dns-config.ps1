# IPv4 DNS Providers
[hashtable]$ipv4dns = [ordered]@{
    quad9_secure = @("9.9.9.9","https://dns.quad9.net/dns-query");
    cloudflare = @("1.1.1.1","https://cloudflare-dns.com/dns-query");
    nextdns = @("45.90.28.187","https://dns.nextdns.io/471cf1");
    adgurad_public = @("94.140.14.14","https://dns.adguard-dns.com/dns-query")
    mullvad_base = @("194.242.2.4","https://base.dns.mullvad.net/dns-query")
}

# IPv6 DNS Providers
[hashtable]$ipv6dns = [ordered]@{
    quad9_secure = @("2620:fe::fe","https://dns.quad9.net/dns-query");
    cloudflare = @("2606:4700:4700::1111","https://cloudflare-dns.com/dns-query");
    nextdns = @("2a07:a8c0::47:1cf1","https://dns.nextdns.io/471cf1");
    adgurad_public = @("2a10:50c0::ad1:ff","https://dns.adguard-dns.com/dns-query")
    mullvad_base = @("2a07:e340::4","https://base.dns.mullvad.net/dns-query")
}

# Get Device Interface Details
$ipv4interfaces=$(Get-DnsClientServerAddress -AddressFamily IPv4)
$ipv6interfaces=$(Get-DnsClientServerAddress -AddressFamily IPv6)

$ipv4interfaceslen = $ipv4interfaces.Count - 1
$ipv6interfaceslen = $ipv6interfaces.Count - 1

# Select the Network Interface to Modify
function Get-UserNetworkInterfaces {

    param (
        [string] $IPFamily
    )

    Write-Host "`n===== SELECT NETWORK INTERFACE =====`n"

    switch ($IPFamily) {
        "ipv4" {
            foreach ($interface in $ipv4interfaces) {
                Write-Host "[ $($ipv4interfaces.IndexOf($interface)) ] $($interface.InterfaceAlias)"
            }
        }
        "ipv6" {
            foreach ($interface in $ipv6interfaces) {
                Write-Host "[ $($ipv6interfaces.IndexOf($interface)) ] $($interface.InterfaceAlias)"
            }
        }
    }

    $selectedinterface = Read-Host "`nSelect Interface [ 0 - "($ipv4interfaceslen)"] ?"
    Write-Host "`n===== SELECTED NETWORK INTERFACE DETAILS =====`n"
    switch ($IPFamily) {
        "ipv4" {
            Write-Host "$($ipv4interfaces[$selectedinterface].InterfaceAlias)"
        }
        "ipv6" {
            Write-Host "$($ipv6interfaces[$selectedinterface].InterfaceAlias)"
        }
    }

    if ($([int]$selectedinterface) -le 9) {
        return $selectedinterface
    }
    else {
        Write-Host "Invalid Input, Please a value between 0 - $ipv4interfaceslen"
        Break
    }

}

# Select the Custom DNS Provider
function Get-CustomDNSProviders {

    param (
        [string] $IPFamily
    )

    Write-Host "`n===== SELECT DNS PROVIDER =====`n"

    $TextInfo = (Get-Culture).TextInfo
    $value = 0
    switch ($IPFamily) {
        "ipv4" {
            foreach ($provider in $ipv4dns.Keys) {
                $value += 1
                $formatedprovider = $TextInfo.ToTitleCase($provider.Replace("_"," "))
                Write-Host "[ $value ] $formatedprovider"
            }
        }
        "ipv6" {
            foreach ($provider in $ipv6dns.Keys) {
                $value += 1
                $formatedprovider = $TextInfo.ToTitleCase($provider.Replace("_"," "))
                Write-Host "[ $value ] $formatedprovider"
            }
        }
    }

    $selecteddnsprovider = Read-Host "`nSelect DNS Provider "

    $primarydnsprovider = switch ($selecteddnsprovider)
    {
        1 {"adgurad_public"}
        2 {"mullvad_base"}
        3 {"quad9_secure"}
        4 {"nextdns"}
        5 {"cloudflare"}
    }

    Write-Host "`n===== SELECTED DNS PROVIDER DETAILS =====`n"
    Write-Host "Selected Provider : $($TextInfo.ToTitleCase($primarydnsprovider.Replace("_"," ")))"
    Write-Host "Primary DNS IP : $($ipv4dns[$primarydnsprovider][0])"
    Write-Host "DNS Over HTTPS : $($ipv4dns[$primarydnsprovider][1])"

    if ($([int]$selectedinterface) -in 1..5) {
        return $primarydnsprovider, $ipv4dns[$primarydnsprovider][0], $ipv4dns[$primarydnsprovider][1]
    }
    else {
        Write-Host "Invalid Input, Please a value between 1 - 5"
        Break
    }
}

# Set the Custom DNS for IPv4 Interface
function Set-CustomDNSProvdierIPv4 {

    param (
        $UserNetworkInterface,
        $PrimaryDNSProvider,
        $PrimaryDNSIP,
        [string] $PrimaryDNSHTTPS
    )

    Set-DnsClientServerAddress -InterfaceAlias $ipv4interfaces[$UserNetworkInterface].InterfaceAlias -ServerAddresses ("$($PrimaryDNSIP)")
    Set-DnsClientDohServerAddress -ServerAddress "$($PrimaryDNSIP)" -DohTemplate "$($PrimaryDNSHTTPS)"

    Get-DnsClientServerAddress -InterfaceAlias $ipv4interfaces[$UserNetworkInterface].InterfaceAlias -AddressFamily IPv4
    Get-DnsClientDohServerAddress -ServerAddress $PrimaryDNSIP
}

# Set the Custom DNS for IPv6 Interface
function Set-CustomDNSProvdierIPv6 {

    param (
        $UserNetworkInterface,
        $PrimaryDNSProvider,
        $PrimaryDNSIP,
        [string] $PrimaryDNSHTTPS
    )

    Set-DnsClientServerAddress -InterfaceAlias $ipv6interfaces[$UserNetworkInterface].InterfaceAlias -ServerAddresses ("$($PrimaryDNSIP)")
    Set-DnsClientDohServerAddress -ServerAddress "$($PrimaryDNSIP)" -DohTemplate "$($PrimaryDNSHTTPS)"

    Get-DnsClientServerAddress -InterfaceAlias $ipv4interfaces[$UserNetworkInterface].InterfaceAlias -AddressFamily IPv6
    Get-DnsClientDohServerAddress -ServerAddress $PrimaryDNSIP
}

# Start Script
Write-Host "`n===== CHANGE WINDOWS DNS CONFIGURATION =====`n"
$ipfamily = Read-Host "`nSelect the IP Address Family [IPv4 / IPv6] ?"

if ($ipfamily.ToLower() -eq "ipv4") {
    Write-Host "IPv4 Selected"
    $selectedinterface = UserNetworkInterfaces -IPFamily $ipfamily
    $selectedprimaryprovider, $primarydnsip, $primarydnshttps = Get-CustomDNSProviders -IPFamily $ipfamily
    Set-CustomDNSProvdierIPv4 -UserNetworkInterface $selectedinterface -PrimaryDNSProvider $selectedprimaryprovider -PrimaryDNSIP $primarydnsip -PrimaryDNSHTTPS $primarydnshttps

}
elseif ($ipfamily.ToLower() -eq "ipv6") {
    Write-Host "IPv6 Selected"
    $selectedinterface = UserNetworkInterfaces -IPFamily $ipfamily
    $selectedprimaryprovider, $primarydnsip, $primarydnshttps = Get-CustomDNSProviders -IPFamily $ipfamily
    Set-CustomDNSProvdierIPv6 -UserNetworkInterface $selectedinterface -PrimaryDNSProvider $selectedprimaryprovider -PrimaryDNSIP $primarydnsip -PrimaryDNSHTTPS $primarydnshttps
}
else {
    Write-Host "Invalid Input, Please enter IPv4 or IPv6"
    Break
}