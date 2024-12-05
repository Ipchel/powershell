param(
    [parameter(Mandatory=$true)]
    [string]$UserName
)

$ADS_ESCAPEDMODE_ON   = 2
$ADS_SETTYPE_DN       = 4
$ADS_FORMAT_X500      = 5

function Invoke-Method {
    param(
        [__ComObject] $object,
        [String] $method,
        $parameters
    )
    $output = $object.GetType().InvokeMember($method, "InvokeMethod", $null, $object, $parameters)
    if ($output) { $output }
}

function Set-Property {
    param(
        [__ComObject] $object,
        [String] $property,
        $parameters
    )
    [Void] $object.GetType().InvokeMember($property, "SetProperty", $null, $object, $parameters)
}

$Pathname = New-Object -ComObject "Pathname"
Set-Property $Pathname "EscapedMode" $ADS_ESCAPEDMODE_ON

# Поиск пользователя по имени
$searcher = [ADSISearcher] "(&(objectClass=user)(sAMAccountName=$UserName))"
$searcher.PropertiesToLoad.AddRange(@("distinguishedName"))

$searchResult = $searcher.FindOne()
if ($searchResult) {
    $userDN = $searchResult.Properties["distinguishedname"][0]

    # Поиск групп, в которые входит пользователь
    $groupSearcher = [ADSISearcher] "(&(objectClass=group)(member=$userDN))"
    $groupSearcher.PropertiesToLoad.AddRange(@("name", "distinguishedName"))

    $groupResults = $groupSearcher.FindAll()
    if ($groupResults.Count -gt 0) {
        foreach ($groupResult in $groupResults) {
            $group = $groupResult.GetDirectoryEntry()
            "" | Select-Object `
                @{
                    Name="GroupName"
                    Expression={$group.name}
                },
                @{
                    Name="DistinguishedName"
                    Expression={$group.distinguishedName}
                }
        }
    } else {
        Write-Output "Пользователь '$UserName' не состоит ни в одной группе."
    }
} else {
    throw "Пользователь с именем '$UserName' не найден."
}