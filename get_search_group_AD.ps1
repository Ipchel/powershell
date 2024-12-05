# Установите параметры подключения к Active Directory
$ldapPath = "LDAP://DC=int,DC=gazprombank,DC=ru"  # Замените на ваш LDAP путь
$searcher = New-Object DirectoryServices.DirectorySearcher
# Запрос имени учетной записи пользователя
$userName = Read-Host "Введите имя учетной записи пользователя"
# Запрос имени группы или шаблона для поиска
$groupName = Read-Host "Введите имя группы или шаблон для поиска"
# Поиск учетной записи пользователя
$searcher.Filter = "(&(objectClass=user)(sAMAccountName=$userName))"
$userResult = $searcher.FindOne()
if ($userResult) {
    Write-Host "Учетная запись пользователя найдена: $($userResult.Properties['sAMAccountName'])"
    # Получение DN пользователя
    $userDN = $userResult.Properties['distinguishedName']
    # Поиск групп, в которых состоит пользователь
    $groupSearcher = New-Object DirectoryServices.DirectorySearcher
    $groupSearcher.Filter = "(&(objectClass=group)(member=$userDN))"
    $groups = $groupSearcher.FindAll()
    if ($groups.Count -gt 0) {
        Write-Host "Группы, в которых состоит пользователь, соответствующие шаблону '$groupName':"
        $foundGroups = @()
        foreach ($group in $groups) {
            $groupNameFromAD = $group.Properties['sAMAccountName']
            if ($groupNameFromAD -like "*$groupName*") {
                $foundGroups += $groupNameFromAD
            }
        }
        if ($foundGroups.Count -gt 0) {
            $foundGroups | ForEach-Object { Write-Host $_ }
        } else {
            Write-Host "Нет групп, соответствующих шаблону '$groupName'."
        }
    } else {
        Write-Host "Пользователь не состоит ни в одной группе."
    }
} else {
    Write-Host "Учетная запись пользователя не найдена."
}