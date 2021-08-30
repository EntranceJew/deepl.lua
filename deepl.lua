local DeepL = {
  new = function(self, API_KEY, o)
    o = o or {}
    o.API_KEY = API_KEY
    setmetatable(o, self)
    self.__index = self
    return o
  end,
  API_KEY = "YOU_FORGOT_TO_SPECIFY_A_KEY",
  SupportedLangs = {
    -- deepl = gmod
    ["bg"] = "bg", -- bulgarian
    ["cs"] = "cs", -- czech
    ["da"] = "da", -- danish
    ["de"] = "de", -- german
    ["el"] = "el", -- greek
    -- ["en-GB"] = "en-PT", -- english (british)
    -- ["en-US"] = "en", -- english (american)
    ["en"] = "en", -- english (unspecified variant for backward compatibility; please select en--gb or en--us instead)
    -- [] = "en-PT",
    ["es"] = "es-ES", -- spanish
    ["et"] = "et", -- estonian
    ["fi"] = "fi", -- finnish
    ["fr"] = "fr", -- french
    -- [] = "he", -- hebrew
    -- [] = "hr", -- croatian
    ["hu"] = "hu", -- hungarian
    ["it"] = "it", -- italian
    ["ja"] = "ja", -- japanese
    -- [] = "ko", -- korean
    ["lt"] = "lt", -- lithuanian
    -- "lv", -- latvian
    ["nl"] = "nl", -- dutch
    -- [] = "no", -- norwegian
    ["pl"] = "pl", -- polish
    ["pt-PT"] = "pt-PT", -- portuguese (all portuguese varieties excluding brazilian portuguese)
    ["pt-BR"] = "pt-BR", -- portuguese (brazilian)
    -- ["pt"] = "", -- portuguese (unspecified variant for backward compatibility; please select pt--pt or pt--br instead)
    -- ["ro"] = "", -- romanian
    ["ru"] = "ru", -- russian
    ["sk"] = "sk", -- slovak
    -- ["sl"] = "", -- slovenian
    ["sv"] = "sv-SE", -- swedish
    -- [] = "th", -- thai
    -- [] = "tr", -- turkish
    -- [] = "uk", -- ukranian
    -- [] = "vi", -- vietnamese
    ["zh"] = "zh-CN", -- chinese simplified
    -- [] = "zh-TW", -- chinese traditional
  },
  Files = {
  },
  DefaultDir = "deepl_lib/resource/localization",
  Endpoint = "https://api.deepl.com/v2/translate",
  DebugPrint = true,
}

-- static functions

DeepL.ParseFile = function(fpath)
  local data = file.Read(fpath, "GAME")
  local lines = string.Explode("\n", data)
  local out = {}
  for i = 1, #lines do
    local line = lines[i]
    if line:sub(1,1) == "#" then continue end
    local key = ""
    local val = ""
    local parts = string.Explode("=", line)
    if #parts > 2 then
      key = parts[1]
      table.remove(parts, 1)
      val = string.Implode("=", parts)
    elseif #parts == 2 then
      key = parts[1]
      val = parts[2]
    else
      -- no funny parts :(
      continue
    end
    out[key] = val
  end
  return out
end

-- instance functions

DeepL.DumpFiles = function(self, target_prop, base_dir)
  base_dir = base_dir or self.DefaultDir
  local dat = self.Files[target_prop]

  for deepl_lang, data in pairs(dat) do
    local dir = base_dir .. "/" .. self.SupportedLangs[deepl_lang]
    local dump = ""
    -- TODO: parse out linebreaks maybe
    for key, value in SortedPairs(data) do
      dump = dump .. key .. "=" .. value .. "\n"
    end
    file.CreateDir(dir)
    file.Write( dir .. "/" .. target_prop .. ".properties.txt", dump )
  end
end

DeepL.TranslateString = function(self, str, source_lang, target_lang, out_table, out_key)
  local dat = {
    auth_key = self.API_KEY,
    source_lang = string.upper(source_lang),
    target_lang = string.upper(target_lang),
    text = str,
    -- split_sentences = "1", -- 0/1/nonewlines
    -- preserve_formatting = "0", -- 0/1
    -- formality = "less", -- default/more/less
    -- glossary_id = nil,
  }

  http.Post( self.Endpoint, dat,
    -- onSuccess function
    function( body, length, headers, code )
      if code ~= 200 and self.DebugPrint then
        PrintTable(headers)
        print( body )
        print( code )
        print( length )
      else
        local result = util.JSONToTable(body)
        out_table[out_key] = result.translations[1].text
      end
    end,
    -- onFailure function
    function( message )
      if self.DebugPrint then
        print( message )
      end
    end
    -- headers shoulda gone here
  )
end

DeepL.DummyTranslateString = function(self, str, source_lang, target_lang, out_table, out_key)
  local dat = {
    auth_key = "test",
    source_lang = string.upper(source_lang),
    target_lang = string.upper(target_lang),
    text = str,
    -- split_sentences = "1", -- 0/1/nonewlines
    -- preserve_formatting = "0", -- 0/1
    -- formality = "less", -- default/more/less
    -- glossary_id = nil,
  }

  timer.Simple(0.1, function()
    if self.DebugPrint then
      PrintTable({"the output", dat, str, source_lang, target_lang, out_table, out_key})
    end
    out_table[out_key] = str
  end)
end

DeepL.ScanForStrings = function(self, target_prop)
  self.Files[target_prop] = {}
  for deepl_lang, gmod_lang in pairs(self.SupportedLangs) do
    local file_path = "resource/localization/" .. gmod_lang .. "/" .. target_prop .. ".properties"
    if file.Exists(file_path, "GAME") then
      self.Files[target_prop][deepl_lang] = DeepL.ParseFile(file_path)
    end
  end
end

DeepL.FindMissingStrings = function(self, source_lang, target_prop)
  local missing_strings = {}
  for deepl_lang, gmod_lang in pairs(self.SupportedLangs) do
    if deepl_lang ~= source_lang then
      local missing = {}
      local missing_count = 0
      for line, _ in pairs(self.Files[target_prop][source_lang]) do
        if self.Files[target_prop][deepl_lang] == nil or self.Files[target_prop][deepl_lang][line] == nil then
          missing_count = missing_count + 1
          table.insert(missing, line)
        end
      end
      if missing_count > 0 then
        missing_strings[deepl_lang] = missing
      end
    end
  end
  return missing_strings
end

DeepL.GetMissingStrings = function(self, source_lang, target_prop, for_real)
  local missing = self:FindMissingStrings(source_lang, target_prop)
  local stagger = 1.0 / 60.0
  local start_time = 0
  for lang, keys in pairs(missing) do
    self.Files[target_prop][lang] = {}
    for i = 1, #keys do
      local line = keys[i]
      local s_str = self.Files[target_prop][source_lang][line]
      local s_slang = source_lang
      local s_tlang = lang
      local s_otbl = self.Files[target_prop][lang]
      local s_okey = line
      if for_real then
        timer.Simple(start_time, function()
          self:TranslateString(
            s_str,
            s_slang,
            s_tlang,
            s_otbl,
            s_okey
          )
        end)
    else
        timer.Simple(start_time, function()
          self:DummyTranslateString(
            s_str,
            s_slang,
            s_tlang,
            s_otbl,
            s_okey
          )
        end)
      end
      start_time = start_time + stagger
    end
  end
  if self.DebugPrint then
    timer.Simple(start_time + 60, function()
      print("all strings are probably in")
    end)
  end
end

return DeepL