## CI and platform coverage

Continuous integration runs on GitHub Actions with the following coverage:

- Linux (ubuntu-latest)
  - Tested with MRI Ruby 2.7, 3.3, 3.4, 4.0, TruffleRuby and JRuby.
  - These runs ensure broad Ruby engine compatibility on Linux.

- macOS (macos-latest) and Windows (windows-latest)
  - Only tested with the latest MRI (Ruby 4.0) to provide basic platform coverage.
  - These jobs are informational/optional (failures do not block the suite).

Notes:
- MRI 2.7 and TruffleRuby runs are marked optional (allowed to fail) to avoid blocking merges while still catching regressions.
- JRuby runs require a JDK; CI sets up the latest LTS Java specified in the workflow.
