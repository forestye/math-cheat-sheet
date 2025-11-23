# Makefile for Math Cheat Sheet

# Compiler
LATEX = xelatex
FLAGS = -interaction=nonstopmode

# Directories
SRC_DIR = src
PDF_DIR = pdfs

# Final Output
FINAL_PDF = math-cheat-sheet.pdf

# Source files
# Find all .tex files, exclude all-in-one.tex
ALL_SRCS = $(wildcard $(SRC_DIR)/*.tex)
MODULE_SRCS = $(filter-out $(SRC_DIR)/all-in-one.tex, $(ALL_SRCS))
ALL_IN_ONE_SRC = $(SRC_DIR)/all-in-one.tex

# Target PDFs for modules
MODULE_PDFS = $(patsubst $(SRC_DIR)/%.tex, $(PDF_DIR)/%.pdf, $(MODULE_SRCS))

# Intermediate all-in-one PDF
ALL_IN_ONE_PDF = $(PDF_DIR)/all-in-one.pdf

# Default target
all: $(FINAL_PDF)

# Rule to create the final PDF
$(FINAL_PDF): $(ALL_IN_ONE_PDF)
	cp $< $@
	@echo "Generated: $@"

# Rule to create all-in-one.pdf
# Depends on all module PDFs being ready
# Runs xelatex inside PDF_DIR so it can find the module PDFs
$(ALL_IN_ONE_PDF): $(MODULE_PDFS) $(ALL_IN_ONE_SRC) | $(PDF_DIR)
	cd $(PDF_DIR) && $(LATEX) $(FLAGS) ../$(ALL_IN_ONE_SRC)

# Rule to compile individual modules
$(PDF_DIR)/%.pdf: $(SRC_DIR)/%.tex | $(PDF_DIR)
	$(LATEX) -output-directory=$(PDF_DIR) $(FLAGS) $<

# Ensure PDF directory exists
$(PDF_DIR):
	mkdir -p $(PDF_DIR)

# Clean up
clean:
	rm -rf $(PDF_DIR)
	rm -f $(FINAL_PDF)

# Clean intermediate files only (keep PDFs)
clean-temp:
	rm -f $(PDF_DIR)/*.aux $(PDF_DIR)/*.log $(PDF_DIR)/*.out $(PDF_DIR)/*.toc

.PHONY: all clean clean-temp

