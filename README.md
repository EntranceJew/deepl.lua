# deepl.lua
For translating things, but in lua.

## Usage
```lua
local deepl_instance = require("deepl.lua"):new("YOUR_API_KEY")
local source_lang = "en"
local prop_file_name = "yourmodname"

deepl_instance:ScanForStrings(prop_file_name)
deepl_instance:GetMissingStrings(source_lang, prop_file_name)
-- run this until all languages have the same number of items
for k, v in pairs(deepl_instance.Files[prop_file_name]) do
  local i = 0
  for k2, v2 in pairs(v) do
    i = i + 1
  end
  print(k, i)
end
-- then, later ...
deepl_instance:DumpFiles(prop_file_name)
-- you will have files in: data/deepl_dir/resource/localization/*/yourmodname.properties.txt
```
