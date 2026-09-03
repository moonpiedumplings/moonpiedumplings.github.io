#!/usr/bin/env sh
cd $(git rev-parse --show-toplevel)/resume
latexmk -C
latexmk main.tex -pdf

cp main.pdf $(git rev-parse --show-toplevel)/_site/resume/Fonseca_Jeffrey_Resume.pdf

latexmk -C
