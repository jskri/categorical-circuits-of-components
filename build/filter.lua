-- Format formulae, diagrams and lemmas for PDF output.

if PANDOC_VERSION and PANDOC_VERSION.must_be_at_least then
    PANDOC_VERSION:must_be_at_least("2.11")
else
    error("pandoc version >=2.11 is required")
end

function Math(elem)
  local text = elem.text
  text, _ = string.gsub(text, "[%(]_", [[(\_]])
  text, _ = string.gsub(text, "[ ]_", [[ \_]])
  text, _ = string.gsub(text, [[|_(%b{})]], function(match)
              return [[\vert___FILTERSTART__]] .. string.sub(match, 2, string.len(match) - 1) .. "__FILTEREND__"
            end)
  text, _ = string.gsub(text, "{", [[\{]])
  text, _ = string.gsub(text, "}", [[\}]])
  text, _ = string.gsub(text, "__FILTERSTART__", "{")
  text, _ = string.gsub(text, "__FILTEREND__", "}")
  text, _ = string.gsub(text, " \\ ", [[ \setminus{} ]])
  text, _ = string.gsub(text, " → ", [[\to{}]])
  text, _ = string.gsub(text, " ⟼ ", [[\mapsto{}]])
  text, _ = string.gsub(text, " = ", [[=]])
  text, _ = string.gsub(text, " ≠ ", [[≠]])
  text, _ = string.gsub(text, " : ", [[:]])
  text, _ = string.gsub(text, " %+ ", [[+]])
  text, _ = string.gsub(text, " ∈ ", [[∈]])
  text, _ = string.gsub(text, " ∉ ", [[∉]])
  text, _ = string.gsub(text, " ∪ ", [[∪]])
  text, _ = string.gsub(text, "⋃ ", [[⋃]])
  text, _ = string.gsub(text, "∏ ", [[∏]])
  text, _ = string.gsub(text, " | ", [[ \mid{} ]])
  text, _ = string.gsub(text, " ", [[~]])
  text, _ = string.gsub(text, "⇒", [[\implies{}]])
  text, _ = string.gsub(text, "∧", [[\wedge{}]])
  text, _ = string.gsub(text, "⟼", [[\mapsto{}]])
  text, _ = string.gsub(text, "𝒫", [[\mathcal{P}]])
  text, _ = string.gsub(text, "if", [[\textsc{if}]])
  text, _ = string.gsub(text, "then", [[\textsc{then}]])
  text, _ = string.gsub(text, "else", [[\textsc{else}]])
  text, _ = string.gsub(text, "choose", [[\textsc{choose}]])
  text, _ = string.gsub(text, "\n", [[\\  ]])
  text, _ = string.gsub(text, [[%b""]], function(match) -- Lua indexes from 1.
              return [[\text{``]] .. string.sub(match, 2, string.len(match) - 1) .. [[''}]]
            end)
  text, _ = string.gsub(text, "t_ok", [[t_{ok}]])
  text, _ = string.gsub(text, "t_last", [[t_{last}]])
  text, _ = string.gsub(text, "W_in", [[W_{in}]])
  text, _ = string.gsub(text, "v_in", [[v_{in}]])
  text, _ = string.gsub(text, "v'_in", [[v'_{in}]])
  text, _ = string.gsub(text, "v‾", [[\bar{v}]])
  text, _ = string.gsub(text, "s_f'", [[s_{f'}]])
  text, _ = string.gsub(text, [[wires_d\textsc{if}f]], [[wires_{diff}]])
  text, _ = string.gsub(text, [[vals_d\textsc{if}f]], [[vals_{diff}]])
  text, _ = string.gsub(text, [[d\textsc{if}f]], [[diff]])
  return pandoc.Math(elem.mathtype, text)
end

function CodeBlock(elem)
  local text = elem.text
  local kind = elem.classes[1]
  if kind == "lemma" then
    -- Format:
    --   name: <lemma-name>\n
    --   <contents>
    -- Example:
    --   name: id
    --   
    --   For each type $t$, there is an $id_t$ component that merely forwards
    --   inputs to outputs, i.e.
    --   
    --   $$id_t = ({α}, {β}, ⋆, (t, (α ⟼ x, β ⟼ ⋆), ⋆) ⟼ ((α ⟼ ⋆, β ⟼ x), ⋆)$$
    --   
    --   where wires $α, β$ have type $t$. Precomposing or post-composing with an
    --   identity component does not alter in any way the input or the output.
    local _, j = string.find(text, "name: ")
    local k = string.find(text, "\n")
    local name = string.sub(text, j + 1, k - 1)
    local contents = string.sub(text, k + 2)
    -- Apply math transformation on inline and display maths.
    contents = string.gsub(contents, "%b$$", function(match)
      local inner = string.sub(match, 2, string.len(match) - 1)
      local new = Math(pandoc.Math("InlineMath", inner)).text
      return "$" .. new .. "$"
    end)
    contents = string.gsub(contents, "%$%$([^%$]+)%$%$", function(match)
      local inner = string.sub(match, 1, string.len(match))
      local new = Math(pandoc.Math("DisplayMath", inner)).text
      return "$$" .. new .. "$$"
    end)
    local theorem = string.format([[
\begin{lemma}[%s]
\label{%s}
%s
\end{lemma}]], name, name, contents)
    return pandoc.RawBlock("tex", theorem)
  elseif kind == "diagram" then
    -- Format:
    --   title: <string>\n
    --   basename: <diagram-basename>\n
    --   <contents>
    -- Example:
    --   title: The functional component $f$.
    --   basename: add
    --   
    --   α:ℕ ┌─────────────┐
    --   ────│      f      │ γ:ℕ
    --   ────│     add     │────
    --   β:ℕ └─────────────┘

    function is_readable(path)
      local f = io.open(path, "r")
      local is_open = (f ~= nil)
      if is_open then io.close(f) end
      return is_open
    end
    local _, j = string.find(text, "title: ")
    local k = string.find(text, "\n", j + 1)
    local title = string.sub(text, j + 1, k - 1)
    local _, l = string.find(text, "basename: ", k + 1)
    local m = string.find(text, "\n", l + 1)
    local basename = string.sub(text, l + 1, m - 1)
    if is_readable(string.format("../diagrams/%s.tikz", basename)) then
      local diagram = string.format([[\mydiagram{../diagrams/%s.tikz}{%s}]], basename, title)
      return pandoc.RawBlock("tex", diagram)
    end
  else
    error("Unknown block kind: " .. kind)
  end
end
