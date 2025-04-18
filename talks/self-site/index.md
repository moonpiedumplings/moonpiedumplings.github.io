---
title: "Your very own site on GitHub Pages"
date: "2025-2-25"
categories: [talks]
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
    toc: true
    license: "CC BY-SA 4.0"
  revealjs:
    incremental: false
    output-file: presentation
    footer: "Jeffrey Fonseca — [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)"
    theme: dark
execute:
  freeze: false
---

::: {.content-hidden when-format="revealjs"}

For the Layer8 Cybersecurity club here at Cal State Northridge, and potentially more clubs, I will do a presentation on how I set up my site with Github pages, and how to set up your own site the same way. 

This guide uses Github Actions to autodeploy, so all users need to do is commit from the web interface of Github, their site will automatically render changes.

Below is the same presentation, rendered to html with the slide titles as headers.

If you want to see the presentation in slides form, click the "RevealJS" format on the right, under "Other formats".

Here is a qr code to the slides:

{{< qrcode https://moonpidumplings.github.io/self-site >}}

<br>

:::


## About me and my site

* Jeffrey Fonseca
  - Using linux for almost 6 years
  - Started blogging just last year
* Site: [moonpiedumplings.github.io](https://moonpiedumplings.github.io/)



## Benefits of a site

* Portfolio and resume
* Notes on longer projects
* Social Media — A few friends follow my blog


## Setup

* Go to [github.com](https://github.com) and create an account
  - Your site will be located at "username.github.io"
* Go to [github.com/moonpiedumplings/blog-template](https://github.com/moonpiedumplings/blog-template) and select "use template"
  - The repo name should be "username.github.io"
  - make sure to select "include all branches"
  - in the github settings, make sure "gh-pages" is selected as the deploy  


## Directory Structure

The files and folders are laid out simply. 

```{.default}
.
|-- _quarto.yml # Configuration for quarto
|-- blog
|   |-- index.md # Directory listing
|   |-- markdown
|   |   `-- index.md
|   `-- quarto
|       `-- index.md
|-- index.md
```

## Directory Structure (cont.)

* The "index.md" within of each folder is what gets rendered into a an html file, a browser page
* The "index.md" in "blog" is a special format called a "listing", rather than a normal article, it generates the list of articles, the filtering, etc on the "blog" page

## Markdown

* [Markdown](https://en.wikipedia.org/wiki/Markdown) is **markup language**
* Enables users to render formatted documents from **plaintext**
* Most static site generators use markdown


## Markdown Code Snippets

<br>

```
`this is code snippets`
```

<br>

They result in unformated, monospace text:

<br>

`this is code snippets`

## Markdown Basics

`*italics*` = *italics*

`**bold**` = **bold**

`[linktext](example.com)` = [linktext](example.com)

## More Markdwon Basics

<br>

`# top level header`

<h1>top level header</h1>

<br>

`## lower level header`

<h2>lower level header<h2>

## Useful HTML in Markdown

`<br>` = line break

<br>

```{.html}
<details><summary>summary text</summary>

collapsable content

</details>
```

<br>

<details><summary>summary text</summary>collapsable content</details>


## Quarto

* Static site generator
* Converts markdown into `html`, the language powering websites.
* Feature Rich by Default
  - Full text search
  - Light and dark theme

## Quarto
* Outputs: website page, pdf, or presentation (html)
* Designed for Data Science, so has integration with Jupyter Notebooks
* Does *not* have any form of templating engine


## Template Engine

Not included in Quarto

```{.jinja2}
{% for i in list %}
  i.attribute
  {% if something %}renderif{% endif %}
{% endfor %}
```

## Questions? Comments? Anything you want to do?

# Thank You!

I hope you use this to host your own blog/site, like I do.




