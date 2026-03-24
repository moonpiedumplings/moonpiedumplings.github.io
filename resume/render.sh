#!/usr/bin/env sh
cd $(git rev-parse --show-toplevel)/resume
latexmk -C
latexmk pdf2.tex -pdf

cp pdf2.pdf $(git rev-parse --show-toplevel)/_site/resume/Fonseca_Jeffrey_Resume.pdf

latexmk -C
