TITLE := Categorical circuits of components
VERSION := 0.1
DATE := june 2024
ABSTRACT := This document defines circuits of components and their algebraic optimisation, based on categorical constructions such as compact closed categories.
KEYWORDS := component, circuit, category theory, composition, optimisation, algebraic identity, cartesian category, cocartesian category, compact closes category

TARGET := categorical-circuits-of-components
DIAGRAMS := $(wildcard ../diagrams/*.tikz)
TEX_INCLUDES := theorem.tex float.tex mydiagram.tex default.tikzstyles
LUA_FILTERS := filter.lua
PANDOC := pandoc
PANDOC_META_FLAGS := -Vtitle-meta="$(TITLE)" -Vtitle="$(TITLE)" -Vsubtitle="version $(VERSION)" -Vdate="$(DATE)" -Vabstract="$(ABSTRACT)" -Vkeywords="$(KEYWORDS)"
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
