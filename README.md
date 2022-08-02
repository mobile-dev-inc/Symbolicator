# Symbolicator

The symbolicator util symbolicates memory leaks and crash reports.

## Install

Run these commands in the terminal

```
git clone https://github.com/mobile-dev-inc/Symbolicator
cd Symbolicator
swift build --configuration release && cp .build/release/symbolicator /usr/local/bin
cd -
```

Uninstall by running `rm /usr/local/bin/symbolicator`

## Usage

```
symbolicator <crash or memory leak> --dsym <app.Dsym>
```

When the `--json` flag is specified, symbolicator will attempt to parse the output and generate a JSON representation.
