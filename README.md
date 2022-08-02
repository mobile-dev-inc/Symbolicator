# Symbolicator

The symbolicator util symbolicates memory leaks and crash reports.

## Usage

```
symbolicator <crash or memory leak> --dsym <app.Dsym>
```

When the `--json` flag is specified, symbolicator will attempt to parse the output and generate a JSON representation.
