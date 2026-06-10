# swift-a11y-linter

A SwiftUI / UIKit accessibility linter that checks Swift source code against WCAG 2.1 Level AA and EU Accessibility Act requirements.

## Features

- Static analysis of SwiftUI and UIKit code for accessibility issues
- WCAG 2.1 Level AA rule set with per-rule severity, level, and section mapping
- EU Accessibility Act / EN 301 549 / EU Directive 2016/2102 compliance flags
- Compliance scoring with configurable penalties and a minimum-score gate
- Multiple reporters: terminal, JSON, GitHub Actions, Xcode, Markdown, HTML
- JSON configuration with rule toggles and path exclusions

## Requirements

- macOS 13 or later
- Swift 5.9 toolchain

## Build

```sh
swift build -c release
```

The binary is produced at `.build/release/swift-a11y-linter`.

## Usage

```sh
swift-a11y-linter <path> [options]
```

### Options

| Flag | Description |
| --- | --- |
| `--config <path>` | Path to JSON config file (default: `a11y.config.json`) |
| `--reporter <type>` | Output format: `cli`, `json`, `github`, `xcode`, `markdown`, `html` |
| `--strict` | Exit with code 1 on any error-severity violation |
| `--require-all` | Require accessibility identifiers on all elements |
| `--use-script-input-files` | Lint files listed in the `SCRIPT_INPUT_FILE_*` env vars (Xcode build phase) |
| `--verbose`, `-v` | Print detailed progress information |
| `--version` | Print version |
| `-h`, `--help` | Show help |

### Examples

```sh
swift-a11y-linter Sources/
swift-a11y-linter Sources/ --strict --reporter github
swift-a11y-linter MyView.swift --reporter html
swift-a11y-linter . --config custom.json --reporter json
```

## Configuration

Rules, severities, compliance settings, excluded paths, and scoring weights live in `a11y.config.json`. Each rule entry can be toggled on or off and tagged with a WCAG level and section. See the bundled `a11y.config.json` for the full schema.

## Rules

| Rule | Severity | WCAG |
| --- | --- | --- |
| `MISSING_A11Y_LABEL` | error | 1.1.1 (A) |
| `MISSING_IMAGE_DESCRIPTION` | error | 1.1.1 (A) |
| `MISSING_FORM_LABEL` | error | 3.3.2 (A) |
| `MISSING_A11Y_HINT` | warning | 3.2.1 (AA) |
| `TOUCH_TARGET_TOO_SMALL` | error | 2.5.5 (AAA) |
| `LOW_CONTRAST_RATIO` | error | 1.4.3 (AA) |
| `COLOR_ONLY_INDICATOR` | warning | 1.4.1 (A) |
| `INACCESSIBLE_CUSTOM_CONTROL` | warning | 4.1.2 (A) |
| `MISSING_VIDEO_SUBTITLES` | error | 1.2.2 (A) |
| `TEMPORAL_MEDIA_NO_TRANSCRIPT` | error | 1.2.3 (A) |
| `AUTOPLAY_WITHOUT_CONTROL` | warning | 2.2.2 (A) |
| `POOR_READING_ORDER` | warning | 2.4.3 (A) |
| `MISSING_A11Y_IDENTIFIER` | info | — |

## CI integration

Use `--reporter github` to surface annotations directly on pull requests:

```yaml
- name: Accessibility lint
  run: swift run swift-a11y-linter Sources/ --strict --reporter github
```

## Xcode build phase

Add a "Run Script" build phase, list the Swift files to lint under **Input Files**, and pass `--use-script-input-files`. Xcode exposes those entries as the `SCRIPT_INPUT_FILE_COUNT` / `SCRIPT_INPUT_FILE_<n>` environment variables, which the linter reads instead of scanning a path — handy for linting only the files in the current build:

```sh
swift-a11y-linter --use-script-input-files --reporter xcode
```

With the `xcode` reporter, violations surface inline in the Xcode issue navigator.

## Testing

```sh
swift test
```

## License

Released under the [MIT License](LICENSE).
