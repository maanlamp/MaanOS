function update ()
  --Check if updating is necessary.
  local internet = require("internet");
  local file = io.open("/maanos/programs/ide.lua", "w");
  for chunk in internet.request("https://raw.githubusercontent.com/maanlamp/MaanOS/master/OpenComputers/IDE/ide.lua") do
    file:write(chunk);
  end
  file:close();
end

update();

--Global objects/APIs
local env = {...};
local term = require("term");
local shell = require("shell");
local event = require("event");
local unicode = require("unicode");
local Array = require("../api/Array");
local component = require("component");
local gpu = component.gpu;

function vw ()
  local w, h = gpu.getResolution();
  return w;
end
function vh ()
  local w, h = gpu.getResolution();
  return h;
end

local document = {
  raw = "",
  isLoaded = false
};

local cursors = Array.from{
  {line = 1, column = 0}
};

local editor = {
  graphicalElements = {
    topbar = {x = 1, y = 1, w = vw(), h = 1, col = 0x222225},
    sidebar = {x = 1, y = 2, w = 25, h = vh() - 2, col = 0x222225},
    bottombar = {x = 1, y = vh(), w = vw(), h = 1, col = 0x00AAFF}
  }
};
editor.views = Array.from{
  {x = 26, y = 2, w = vw() - 25, h = vh() - 2, scrollX = 0, scrollY = 0, document = document}
};
function editor.getTextToDisplay (view) --Sometimes gives back more lines, fix that shit!
  local startpos = 0;
  for i = 0, -view.scrollY do
    startpos = view.document.raw:find("\n", startpos) + 1;
  end
  local endpos = startpos;
  for i = 0, view.h do
    endpos = view.document.raw:find("\n", endpos + 1);
  end
  return view.document.raw:sub(startpos, endpos - 1);
end
function editor.draw ()
  gpu.setBackground(0x000000);
  gpu.fill(1, 1, vw(), vh(), " "); --clear screen
  for k,v in pairs(editor.graphicalElements) do
    local element = editor.graphicalElements[k];
    gpu.setBackground(element.col);
    gpu.fill(element.x, element.y, element.w, element.h, " ");
  end
  editor.views:forEach(function (view)
    gpu.setBackground(0x111112);
    gpu.fill(view.x, view.y, view.w, view.h, " ");
    local textToDisplay = editor.getTextToDisplay(view);
    local i = 0;
    for line in textToDisplay:gmatch("(.-)\n") do
      local lineNumber = i + 1 - view.scrollY;
      gpu.setForeground(0x444444);
      gpu.set(view.x + 4 - tostring(lineNumber):len(), view.y + i, tostring(lineNumber)); --Line numbers
      gpu.setForeground(0xFFFFFF);
      gpu.set(view.x + 6, view.y + i, line);
      i = i + 1;
    end
    colourise(view, view.document.tokens);
  end);
end

function document:load (path)
  local ok, err = pcall(function ()
    local file = io.open(path, "r");
    for line in file:lines() do
      self.raw = self.raw .. line .. "\n";
    end
    file:close();
  end);
  self.isLoaded = ok;
  return ok;
end

function tokenise (text)
  local Cursor = {position = 1, _SAVEDPOS = 0};
  function Cursor:step ()
    self.position = self.position + 1;
  end
  function Cursor:save ()
    self._SAVEDPOS = self.position;
    return self.position;
  end
  function Cursor:restore ()
    self.position = self._SAVEDPOS;
  end
  local Character = {};
  function Character:value (offset)
    local position = Cursor.position + (offset or 0);
    return text:sub(position, position);
  end
  --maybe implement next and previous
  function Character:is (...)
    local args = {...};
    local matches = Array.from{};
    for i, pattern in ipairs(args) do
      matches:push(not not self:value():find(pattern)); --not not = toboolean()
    end
    return matches:some(function (v) return v == true end);
  end
  function eat ()
    local temp = Character:value();
    Cursor:step();
    return temp;
  end

  local tokens = Array.from{};
  local whitespace = "%s";
  local minus = "-";
  local linebreak = "\n";
  local punctuation = "[;%{%}%[%]%(%),:]";
  local string = '[\'\'\"\"]'; --This weird shit is required to identify strings (fix later?)
  local number = "%d";
  local hexadecimalNumber = "[%xx]";
  local operator = "[.=+%-%*%^~<>?&|!:]";
  local identifierStart = "[a-zA-Z$_]";
  local identifier = "[%w_$]";
  local identifierTypes = {
    controller = Array.from{"for", "while", "if", "else", "elseif", "end", "break", "do", "repeat", "until"},
    definition = Array.from{"local", "function"},
    operator = Array.from{"return", "in", "and", "or"},
    literal = Array.from{"true", "false", "nil"}
  };

  function getlineAndColumn (position)
    local line = 1;
    local column = 0;
    for i = 1, position do
      if text:sub(i, i) == "\n" then
        line = line + 1;
        column = 0;
      else
        column = column + 1;
      end
    end
    return line, column;
  end

  function LexicalToken (type, lexeme, position)
    local token =  {
      type = type,
      lexeme = lexeme,
      position = position
    };
    token.line, token.column = getlineAndColumn(token.position);
    return token;
  end

  while Cursor.position <= #text do
    (function () --Setup to emulate continue statement
      if Character:is(whitespace) then
        while Character:is(whitespace) do
          Cursor:step();
        end
        return;
      end
      --Comments
      if Character:is(minus) then
        local position = Cursor:save();
        local lexeme = eat();
        if Character:is(minus) then
          while not Character:is(linebreak) do
            lexeme = lexeme..eat();
          end
          return tokens:push(LexicalToken("comment", lexeme, position));
        else
          Cursor:restore();
        end
      end
      --Punctuation
      if Character:is(punctuation) then
        local position = Cursor:save();
        local lexeme = eat();
        while Character:is(punctuation) do
          lexeme = lexeme..eat();
        end
        return tokens:push(LexicalToken("punctuation", lexeme, position));
      end
      --Strings
      if Character:is(string) then
        local position = Cursor.position;
        local stringType = Character:value();
        local lexeme = eat();
        while not Character:is(stringType) do
          lexeme = lexeme..eat();
        end
        lexeme = lexeme..eat();
        return tokens:push(LexicalToken("string", lexeme, position));
      end
      --Numbers
      if Character:is(number) then
        local position = Cursor:save();
        local lexeme = eat();
        while Character:is(number) or Character.is(hexadecimalNumber) do
          lexeme = lexeme..eat();
        end
        return tokens:push(LexicalToken("number", lexeme, position));
      end
      --Operators
      if Character:is(operator) then
        local position = Cursor:save();
        local lexeme = eat();
        while Character:is(operator) do
          lexeme = lexeme..eat();
        end
        return tokens:push(LexicalToken("operator", lexeme, position));
      end
      --Identifiers
      if Character:is(identifierStart) then
        local position = Cursor:save();
        local lexeme = eat();
        while Character:is(identifier) do
          lexeme = lexeme..eat();
        end
        for type, patterns in pairs(identifierTypes) do
          if patterns:some(function (pattern) return lexeme == pattern end) then
            return tokens:push(LexicalToken(type, lexeme, position))
          end
        end
        return tokens:push(LexicalToken("identifier", lexeme, position));
      end
      --If nothing else (remove later?)
      Cursor:step();
    end)();
  end

  for i = #tokens, 1, -1 do --Function Names and Declarations (-> func <- (...) and function -> blabla.blala:asdasd <- (...) respectively)
    local token = tokens[i];
    if token.lexeme == "function" then
      local insertPos = i + 1;
      if not tokens[insertPos].lexeme:find("%(") then --ignore anonymous functions
        local startPos = tokens[insertPos].position;
        local newTokenLexeme = "";
        local ii = 1;
        while not tokens[i + ii].lexeme:find("%(") do
          newTokenLexeme = newTokenLexeme .. tokens[i + ii].lexeme;
          ii = ii + 1;
        end
        tokens[insertPos] = LexicalToken("functionName", newTokenLexeme, startPos);
        tokens:splice(insertPos + 1, insertPos + ii - 2);
      end
    elseif token.type == "identifier" and tokens[i + 1].lexeme:find("[%(%{%\"%\']") then
      token.type = "functionCall";
    end
  end
  return tokens;
end

function colourise (view, tokens)
  if not tokens or #tokens < 1 then return end;

  function printToken (token, i)
    local previousColour = gpu.getForeground();
    function setColourandPrint (colour)
      gpu.setForeground(colour);
      gpu.set(view.x + 6 + token.column - 1, view.y + view.scrollY + i - 1, token.lexeme);
      gpu.setForeground(previousColour);
    end
    if     token.type == "punctuation" then
      return setColourandPrint(0x909090);
    elseif token.type == "operator" then
      return setColourandPrint(0xFF0080);
    elseif token.type == "definition" or token.type == "controller" or token.type == "functionCall" then
      return setColourandPrint(0x76C9F2);
    elseif token.type == "string" then
      return setColourandPrint(0xFFFF00);
    elseif token.type == "number" or token.type == "literal" then
      return setColourandPrint(0xAE81FF);
    elseif token.type == "functionName" then
      return setColourandPrint(0xA6E221);
    elseif token.type == "comment" then
      return setColourandPrint(0x7C617C);
    end
  end

  --Keep view boundaries in mind
  tokens:forEach(function (token, i)
    if type(token) ~= "table" then return end;
      if token.line > -view.scrollY  then --and token.line < -view.scrollY + view.h
        printToken(token, i);
      end
  end);
end

editor.views[1].document:load(env[1]);
editor.draw();