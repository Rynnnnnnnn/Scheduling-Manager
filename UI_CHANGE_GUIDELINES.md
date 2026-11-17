# UI-Only Change Guidelines

## Rule

**Main functions must not be changed. Only the UI may be changed.**

All application logic in `index.html` is considered off-limits for visual/design work. If a fix appears to require changing logic, stop and ask first.

## What you MAY change

- CSS inside the `<style>` block of `index.html` (layout, spacing, colors, typography, responsive breakpoints).
- Static HTML markup (element structure, wrapper `div`s, classes, visible text, icons, `aria-*` labels) **as long as every JavaScript hook is preserved**.
- Purely visual presentation, including CSS-only show/hide and alignment fixes.

## What you MUST NOT change

- Anything inside the `<script>` block: helper functions, storage/load/save functions, validation, overlap checks, package-session accounting, render functions, and event handlers.
- Storage keys (`daybook-bookings-v1`, `daybook-clients-v1`, `daybook-packages-v1`) or the saved data shape.
- Any `id`, `name`, or `data-*` attribute used by the script (for example `#bookingList`, `#weekGrid`, `#clientInput`, `#saveButton`).
- Classes the script queries or generates (for example `.view-panel`, `.booking`, `.week-day`).
- Form constraints that logic depends on (`required`, `min`, `max`, `maxlength`, `step`).
- The markup strings produced by `render()`, `renderWeek()`, `renderClients()`, and `renderPackages()`.

## Checklist before finishing a UI change

1. Prefer a CSS-only solution; touch HTML only when the layout truly needs it.
2. Confirm no `id`, `name`, `data-*`, or script-referenced class was renamed or removed.
3. Confirm no `<script>` code was edited.
4. Manually verify the core flows still work: add/edit/delete booking, client/package forms, search/filter, week navigation, and tab switching.

## Example of an allowed change

The mobile stat-card alignment fix only added `display: flex; flex-direction: column;` to `.stat` and changed `.stat-value` to `margin-top: auto; padding-top: 7px;`. No functions, data, or behavior were modified.
