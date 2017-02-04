PANDOC=pandoc
BASEDIR=$(CURDIR)
INPUTDIR=$(BASEDIR)/source
OUTPUTDIR=$(BASEDIR)/output
TEMPLATEDIR=$(INPUTDIR)/templates
STYLEDIR=$(BASEDIR)/style
BIBFILE=$(INPUTDIR)/references.bib

help:
	@echo '																			'
	@echo 'Usage: make pdf -  generate a PDF file'

pdf:
	pandoc "$(INPUTDIR)"/*.md \
	-o "$(OUTPUTDIR)/thesis.pdf" \
	-H "$(STYLEDIR)/preamble.tex" \
	--template="$(STYLEDIR)/template.tex" \
	--bibliography="$(BIBFILE)" 2>pandoc.log \
	--csl="$(STYLEDIR)/reference.csl" \
	--highlight-style pygments \
	-V fontsize=12pt \
	-V papersize=letter \
	-V documentclass:report \
	-N \
	--latex-engine=xelatex
