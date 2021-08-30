Set-Location -Path "$PSScriptRoot"

$mod_name = (Get-Item -Path (Get-Location)).Name
$mod_name = $mod_name -replace "_",""

$langs = Get-ChildItem -Path "$PSScriptRoot/../../data/deepl_lib/resource/localization"

for ($i = 0; $i -lt $langs.Count; $i++) {
  $path = $langs[$i].Name
  $parts = $path.Split("-")
  $opath = $path
  if ($parts.Count -gt 1) {
    $opath = $parts[0] + "-" + $parts[1].ToUpper()
  }
  $res = $langs[$i].FullName
  $x = Get-Item -Path "$res/$mod_name.properties.txt"

  $cool_path = "./resource/localization/" + $opath
  $uncool_path = $x.FullName

  New-Item -ItemType Directory -Force -Path "$cool_path"
  Move-Item -Path "$uncool_path" -Destination "$cool_path/$mod_name.properties" -Force
}