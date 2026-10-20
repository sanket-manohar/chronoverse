# Security Policy

## Supported versions

Only the latest published version of Chronoverse receives fixes, when the maintainers choose to
provide them. Older versions are not maintained.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Instead, use the repository's private
vulnerability reporting ("Report a vulnerability" under the Security tab) and include:

- a description of the problem and its impact;
- steps or code to reproduce it;
- the package version and platform.

Reports are reviewed on a best-effort basis. There is no guaranteed response time, no bug bounty,
and no obligation to fix any reported issue.

## Scope notes

- Chronoverse has no network access, no storage and no third-party dependencies, which keeps its
  attack surface small.
- Parsing functions (`ICalendar.decode`, `RecurrenceRule.parse`, `ChronoFormat.tryParse`,
  `NaturalDateParser`) are designed to fail safely on malformed input, but you should still
  validate and size-limit any untrusted input (for example uploaded `.ics` files) before passing
  it to them.

## No warranty

Security information is provided without warranty. See the [DISCLAIMER](DISCLAIMER.md).
