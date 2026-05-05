TITLE := Categorical circuits of components
AUTHOR := jskri@proton.me
VERSION := 0.2
DATE := May 2026
ABSTRACT := Software systems tend to grow in complexity until they become impossible to reason about. A natural response is to build systems by assembling well-understood components, but this requires a precise notion of what a component is, how components compose, and how composed systems can be simplified. We present a framework addressing these three points. A component is formally defined as a stateful, time-aware entity that consumes and produces typed values on input and output wires. We then progressively enrich the language of composition by drawing on category theory: bare categories give associativity, cartesian categories add duplication and parallel execution, cocartesian categories add alternation, and compact closed categories enable feedback and loops. At each stage, the resulting algebraic identities provide a basis for optimising circuits of components by equational reasoning. The framework is illustrated throughout with concrete examples and diagrams. The source and PDF are available at \url{https://github.com/jskri/categorical-circuits-of-components}.
KEYWORDS := component, circuit, category theory, composition, optimisation, algebraic identity, cartesian category, cocartesian category, compact closes category

TARGET := categorical-circuits-of-components
DIAGRAMS := $(wildcard ../diagrams/*.tikz)
TEX_INCLUDES := theorem.tex float.tex mydiagram.tex default.tikzstyles
LUA_FILTERS := filter.lua
PANDOC := pandoc
PANDOC_META_FLAGS := -Vtitle-meta="$(TITLE)" -Vtitle="$(TITLE)" -Vauthor="$(AUTHOR)" -Vsubtitle="version $(VERSION)" -Vdate="$(DATE)" -Vabstract="$(ABSTRACT)" -Vkeywords="$(KEYWORDS)"
PANDOC_FLAGS := --standalone --toc --pdf-engine=xelatex --number-sections -Vlof=1 -Vmargin-left=3.5cm -Vmargin-right=3.5cm -Vcolorlinks $(PANDOC_META_FLAGS)
LATEX := xelatex
LATEX_FLAGS :=


$(TARGET).pdf: $(TARGET).tex $(TARGET).toc

$(TARGET).toc: $(TARGET).tex

$(TARGET).pdf $(TARGET).toc:
	@echo -n "Building table of contents: $@ ..."
	@$(LATEX) $(LATEX_FLAGS) -jobname=$(basename $@ .pdf) $^
	@echo "done."

$(TARGET).tex: ../$(TARGET).md
	@echo -n "Building tex: $@ ..."
	@$(PANDOC) $^ $(PANDOC_FLAGS) $(LUA_FILTERS:%=--lua-filter %) $(TEX_INCLUDES:%=--include-in-header %) -o $@
	@echo "done."

.PHONY: clean
clean:
	@echo -n "Cleaning... "
	@rm -f $(TARGET).pdf $(TARGET).dvi $(TARGET).tex $(TARGET).aux $(TARGET).lof $(TARGET).log $(TARGET).toc missfont.log
	@echo "done."
