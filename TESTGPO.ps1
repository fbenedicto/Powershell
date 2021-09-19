#AnalizaGPOSeguridad V0.1
#Script para detectar politicas de grupo que no se hayan replicado correctamente contra los DC's entre otras funciones 
#Ferran Benedicto 09/2021

[System.Windows.MessageBox]::Show(

'Si solo deseas comprobar alguna validación, puedes saltar a la proxima validación con "ESC".

**NOTA: Puedes tomar como referencia los datos del ejecutable desde el Studio.

**NOTA: Si se introduce un valor no valido/inexistente sobre alguna de las validaciones se cerrara el programa**

',

'Mensaje','YesNo','Warning')


# Validación 1 - Replica SYSVOL 

function Get-ReplicacionGPO {
  
    [CmdletBinding()]
    PARAM (
        [parameter(Mandatory = $True, ParameterSetName = "One")]
        [String[]]$GPOName,
        [parameter(Mandatory = $True, ParameterSetName = "All")]
        [Switch]$All
    )
    BEGIN {
        TRY {
            if (-not (Get-Module -Name ActiveDirectory)) { Import-Module -Name ActiveDirectory -ErrorAction Stop -ErrorVariable ErrorBeginIpmoAD }
            if (-not (Get-Module -Name GroupPolicy)) { Import-Module -Name GroupPolicy -ErrorAction Stop -ErrorVariable ErrorBeginIpmoGP }
        }
        CATCH {
            Write-Warning -Message "[START] Algo ha salido mal"
            IF ($ErrorBeginIpmoAD) { Write-Warning -Message "[START] Error al importar el módulo Active Directory" }
            IF ($ErrorBeginIpmoGP) { Write-Warning -Message "[START] Error al importar el módulo de GPO" }
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    PROCESS {
        FOREACH ($DomainController in ((Get-ADDomainController -ErrorAction Stop -ErrorVariable ErrorProcessGetDC -filter *).hostname)) {
            TRY {
                IF ($psBoundParameters['GPOName']) {
                    Foreach ($GPOItem in $GPOName) {
                        $GPO = Get-GPO -Name $GPOItem -Server $DomainController -ErrorAction Stop -ErrorVariable ErrorProcessGetGPO

                        [pscustomobject][ordered] @{
                            "GPO"      = $GPOItem
                            "Controlador dominio"     = $DomainController
                            "Version usuario"           = $GPO.User.DSVersion
                            "SysVol Versión Usuario"     = $GPO.User.SysvolVersion
                            "Versión equipo"       = $GPO.Computer.DSVersion
                            "Sysvol versión equipo" = $GPO.Computer.SysvolVersion
                            
                            
                 
                        }#PSObject
                    }#Foreach ($GPOItem in $GPOName)
                }#IF ($psBoundParameters['GPOName'])
                IF ($psBoundParameters['All']) {
                    $GPOList = Get-GPO -All -Server $DomainController -ErrorAction Stop -ErrorVariable ErrorProcessGetGPOAll

                    foreach ($GPO in $GPOList) {
                        [pscustomobject][ordered] @{
                            "GPO"     = $GPO.DisplayName
                            "Controlador dominio"     = $DomainController
                            "Version usuario"           = $GPO.User.DSVersion
                            "SysVol Versión Usuario"     = $GPO.User.SysvolVersion
                            "Versión equipo"       = $GPO.Computer.DSVersion
                            "Sysvol versión equipo" = $GPO.Computer.SysvolVersion
                        }#PSObject
                    }
                }#IF ($psBoundParameters['All'])
            }#TRY
            CATCH {
                Write-Warning -Message "[PROCESO] Algo ha salido mal"
                IF ($ErrorProcessGetDC) { Write-Warning -Message "[PROCESO] Error al ejecutar la recuperación de controladores de dominio con Get-ADDomainController" }
                IF ($ErrorProcessGetGPO) { Write-Warning -Message "[PROCESO] Error al ejecutar Get-GPO" }
                IF ($ErrorProcessGetGPOAll) { Write-Warning -Message "[PROCESO] Error al ejecutar Get-GPO -All" }
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }#FOREACH
    }#PROCESS
}

#GComprueba si han aplicado las ACL'S en un directorio

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Check replicas GPO SYSVOL'
$form.Size = New-Object System.Drawing.Size(600,200)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'Aceptar'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(800,20)
$label.Text = 'Introduce el nombre COMPLETO de la GPO y pulsa Enter.'
$form.StartPosition = 'CenterScreen'
$form.Controls.Add($label)

$label1 = New-Object System.Windows.Forms.Label
$label1.Location = New-Object System.Drawing.Point(10,70)
$label1.Size = New-Object System.Drawing.Size(800,20)
$label1.Text = 'Si no deseas validar SYSVOL, pulsa ESC para saltar a la proxima validación.'
$form.StartPosition = 'CenterScreen'
$form.Controls.Add($label1)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,40)
$textBox.Size = New-Object System.Drawing.Size(310,20)
$form.Controls.Add($textBox)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancelar'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)
 

$form.Topmost = $true

$form.Add_Shown({$textBox.Select()})
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::$result)
{
    $x = $textBox.Text
    $x
}




Get-ReplicacionGPO -GPOName $textbox.Text | Out-GridView -Title "Replicación GPO $(Get-Date)" -PassThru | Export-Csv "C:\Temp\$((Get-Date).ToString("yyyyMMdd_HHmmss"))_GPO_CHECK_SYSVOL.csv" -NoTypeInformation


#Get-ReplicacionGPO -All | Out-GridView -Title "Replicación GPO $(Get-Date)" -PassThru | Export-Csv "C:\Temp\$((Get-Date).ToString("yyyyMMdd_HHmmss"))_GPO_CHECK_SYSVOL_ALL.csv" -NoTypeInformation

#Check 2 ACL's

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Check ACLs'
$form.Size = New-Object System.Drawing.Size(600,200)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'Aceptar'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(800,20)
$label.Text = 'Introduce la ruta para comprobar permiso FileSystem. Ej: C:\Applications\'
$form.StartPosition = 'CenterScreen'
$form.Controls.Add($label)

$label1 = New-Object System.Windows.Forms.Label
$label1.Location = New-Object System.Drawing.Point(10,70)
$label1.Size = New-Object System.Drawing.Size(800,20)
$label1.Text = 'Si no deseas validar las ACLs, ulsa ESC para saltar a la proxima validación.'
$form.StartPosition = 'CenterScreen'
$form.Controls.Add($label1)

$textBox1 = New-Object System.Windows.Forms.TextBox
$textBox1.Location = New-Object System.Drawing.Point(10,40)
$textBox1.Size = New-Object System.Drawing.Size(310,20)
$form.Controls.Add($textBox1)


$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancelar'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)
 

$form.Topmost = $true

$form.Add_Shown({$textBox1.Select()})
$result = $form.ShowDialog()

if ($result1 -eq [System.Windows.Forms.DialogResult]::$result1)
{
    $x = $textBox1.Text
    $x
}


Get-Acl $textbox1.Text  | Out-GridView -Title "Revision ACL's $(Get-Date)" -PassThru | select -ExpandProperty access |Export-Csv "C:\Temp\$((Get-Date).ToString("yyyyMMdd_HHmmss"))_GPO_CHECK_ACL.csv" -NoTypeInformation 



#Check 3 Applocker

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Check APPLOCKER'
$form.Size = New-Object System.Drawing.Size(600,200)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'Aceptar'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(800,20)
$label.Text = 'Introduce el nombre de usuario o grupo para comprobar. Ej: "Todos"'
$form.StartPosition = 'CenterScreen'
$form.Controls.Add($label)

$textBox1 = New-Object System.Windows.Forms.TextBox
$textBox1.Location = New-Object System.Drawing.Point(10,40)
$textBox1.Size = New-Object System.Drawing.Size(310,20)
$form.Controls.Add($textBox1)

$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(10,70)
$label2.Size = New-Object System.Drawing.Size(800,20)
$label2.Text = 'Introduce la ruta completa del ejecutable. Ej: C:\Program\test.exe'
$form.StartPosition = 'CenterScreen'
$form.Controls.Add($label2)

$textBox2 = New-Object System.Windows.Forms.TextBox
$textBox2.Location = New-Object System.Drawing.Point(10,90)
$textBox2.Size = New-Object System.Drawing.Size(310,20)
$form.Controls.Add($textBox2)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancelar'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)
 

$form.Topmost = $true

$form.Add_Shown({$textBox1.Select()})
$result = $form.ShowDialog()

if ($result1 -eq [System.Windows.Forms.DialogResult]::$result1)
{
    $x = $textBox1.Text
    $x
}


Get-AppLockerPolicy –Effective –XML > C:\Effective.xml

Test-AppLockerPolicy -XMLPolicy C:\Effective.xml -Path $textBox2.text -User $textBox1.Text | Out-GridView -Title "Revision APPLOCKER $(Get-Date)" -PassThru
