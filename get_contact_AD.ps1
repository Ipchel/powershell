param(
  [parameter(Mandatory=$true)]
    $GroupName
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
  if ( $output ) { $output }
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

$searcher = [ADSISearcher] "(&(objectClass=group)(name=$GroupName))"
$searcher.PropertiesToLoad.AddRange(@("distinguishedName"))

$searchResult = $searcher.FindOne()
if ( $searchResult ) {
  $groupDN = $searchResult.Properties["distinguishedname"][0]
  Invoke-Method $Pathname "Set" @($groupDN,$ADS_SETTYPE_DN)
  $path = Invoke-Method $Pathname "Retrieve" $ADS_FORMAT_X500
  $group = [ADSI] $path
  foreach ( $memberDN in $group.member ) {
    Invoke-Method $Pathname "Set" @($memberDN,$ADS_SETTYPE_DN)
    $path = Invoke-Method $Pathname "Retrieve" $ADS_FORMAT_X500
    $member = [ADSI] $path
    "" | Select-Object `
      @{
        Name="mail"
        Expression={$member.mail[0]}
      },
      @{
        Name="member_objectClass"
        Expression={$member.ObjectClass[$member.ObjectClass.Count - 1]}
      },
      @{
        Name="member_sAMAccountName";
        Expression={$member.sAMAccountName[0]}
      }
  }
}
else {
  throw "Group not found"
}