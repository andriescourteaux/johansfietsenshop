# Mode Home Switch Navigation Design

## Context

The current site already supports two visual modes:

- bike mode
- drive mode

The active mode currently affects:

- header logo
- homepage hero image
- the visible shop switch link in the header
- the `merken en verdelers` destination
- shared-page mode persistence through URL and client-side fallback

At the moment, the visible shop switch still links to the standalone `/bikeshop/` or `/driveshop/` page, and the homepage overview cards for Bike and Drive also link to those standalone pages.

## Goal

Make the homepage the primary entrypoint for both modes.

The site should still keep the standalone `/bikeshop/` and `/driveshop/` pages available as routes, but the regular site navigation should no longer link to them.

## Approved Decisions

- The visible shop switch in the header must link to the homepage in the opposite mode.
- The homepage overview cards for `Bikeshop` and `Driveshop` must also link to the homepage in the corresponding mode.
- The standalone `/bikeshop/` and `/driveshop/` pages stay available but are no longer used in normal navigation.
- Existing mode-aware behavior for logo, hero image, `merken en verdelers`, contact links, footer links, and shared-page persistence stays intact.

## Navigation Behavior

### Header switch link

In bike mode:

- label remains `Driveshop`
- destination becomes `/?mode=drive`

In drive mode:

- label remains `Bikeshop`
- destination becomes `/?mode=bike`

### Homepage overview cards

The overview card labeled `Bikeshop` links to:

- `/?mode=bike`

The overview card labeled `Driveshop` links to:

- `/?mode=drive`

### Standalone shop pages

These pages remain accessible directly:

- `/bikeshop/`
- `/driveshop/`

But they are no longer linked from:

- the header switch
- the homepage overview cards

## Technical Approach

This is a small navigation-only adjustment.

- Update the mode helper so the switch hrefs point to the homepage mode URLs rather than the standalone shop pages.
- Update the homepage overview card hrefs so they also point to homepage mode URLs.
- Keep all existing mode data attributes and client-side persistence behavior intact.
- Extend verification to ensure the normal navigation no longer links directly to the standalone shop pages.

## Verification Targets

Implementation should verify:

- in bike mode, the header switch links to `/?mode=drive`
- in drive mode, the header switch links to `/?mode=bike`
- the home overview card `Bikeshop` links to `/?mode=bike`
- the home overview card `Driveshop` links to `/?mode=drive`
- the header and home overview no longer contain direct navigation links to `/bikeshop/` or `/driveshop/`
- Hugo build still succeeds
