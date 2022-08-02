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
symbolicator <.crash file or memory leak> --dsym <app.Dsym>
```

When the `--json` flag is specified, symbolicator will attempt to parse the output and generate a JSON representation.


## Contributing

Feel free to open a pull request! We also love to learn if you find this tool useful.

