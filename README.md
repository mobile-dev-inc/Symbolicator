[![Run tests](https://github.com/mobile-dev-inc/Symbolicator/actions/workflows/test.yml/badge.svg)](https://github.com/mobile-dev-inc/Symbolicator/actions/workflows/test.yml)

# Symbolicator

The symbolicator util symbolicates memory leaks and crash reports.

## Install

Using homebrew:
```
brew tap mobile-dev-inc/tap
brew install symbolicator
```

## Usage

```
# Symbolicate a crash report
symbolicator YourApp.crash --dsym YourApp.Dsym

# Symbolicate a memory leak
leaks 1234 | symbolicator --dsym YourApp.Dsym -

# Parse the memory leak to json
symbolicator --json memory_leak.txt
```

When the `--json` flag is specified, symbolicator will attempt to parse the output and generate a JSON representation.

## Contributing

Feel free to open a pull request! We also love to learn if you find this tool useful.

