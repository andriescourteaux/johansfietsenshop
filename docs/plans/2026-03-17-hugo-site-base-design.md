# Hugo Site Base Design

## Context

The workspace at `K:\Coding\Site2` is currently empty. This project will start as a fresh Hugo site rather than an edit to an existing repository or theme.

## Goal

Build a sober, Dutch-language Hugo website base with:

- a homepage
- a `contact` page
- a `merken en verdelers` page
- a `driveshop` page
- a `bikeshop` page

## Approved Decisions

- The site will be built with Hugo.
- The visible site language will be Dutch.
- The site style should be sober and informative rather than commercial.
- The homepage must contain a large image-filling banner with a placeholder image.
- The homepage header sits on top of the banner image.
- The primary navigation shown in the header is:
  - Contact
  - Bikeshop
  - Driveshop
  - Merken en verdelers
- The content pages will use a single shared page layout.
- The contact page includes a placeholder contact form with no backend submission.

## Information Architecture

The site will expose the following routes:

- `/`
- `/contact/`
- `/merken-en-verdelers/`
- `/driveshop/`
- `/bikeshop/`

The homepage acts as the visual entry point. The other four pages act as stable, informational landing pages.

## Homepage Design

The homepage should open with a full-screen hero banner using a placeholder image. The hero includes:

- an overlaid header/navigation
- a readable overlay treatment so text remains legible
- a short brand or introductory text block

Below the hero, the page continues with quiet, informative content blocks that direct users toward the four main site sections.

## Interior Page Design

All four interior pages share one layout for consistency and low maintenance.

### Contact

- static contact details
- a visible placeholder form
- fields such as name, email, subject, and message
- a clear note that online sending is not active yet

### Merken en verdelers

- structured placeholder blocks or lists for brands and dealers
- built to be easy to fill in later

### Driveshop

- short introduction
- a few highlight blocks
- a closing contact-oriented call to action

### Bikeshop

- short introduction
- a few highlight blocks
- a closing contact-oriented call to action

## Visual Direction

The visual direction is sober, spacious, and businesslike:

- restrained color use
- clear typography
- generous whitespace
- subtle borders and layout separators
- no aggressive sales styling

The homepage hero may use a dark or soft overlay to preserve readability over the placeholder image.

## Technical Structure

The Hugo site will use:

- `content/` for the homepage and four page files
- `layouts/_default/` for shared page templates
- `layouts/index.html` for the homepage template
- `layouts/partials/` for shared header, head, and footer partials
- `static/` for the placeholder banner image
- a central stylesheet for layout, hero, navigation, forms, and responsive rules

## Responsive Behavior

The site should render cleanly on desktop and mobile:

- hero remains image-led on small screens
- header navigation remains readable and usable
- content width and spacing scale down cleanly
- the contact form stacks naturally on narrow viewports

## Out of Scope

These items are intentionally excluded from this base version:

- backend form submission
- CMS integrations
- dynamic product catalogs
- advanced filtering
- multilingual switching
- ecommerce flows

## Verification Targets

Implementation should verify:

- Hugo builds without errors
- all five routes render
- homepage hero fills the viewport
- header navigation appears over the hero on the homepage
- contact form is present and clearly marked as a placeholder
