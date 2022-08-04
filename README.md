# Symbolicator

The binary code of apps can contain symbol information. With symbol information it is possible look up the function name that belongs to a part of the executable code of the app binary.

There is a compiler flag that removes this symbol information from the binary. In Xcode this flag is DEPLOYMENT_POSTPROCESSING called. When set to Yes, the compiler will remove the symbol information, resulting in a smaller binary.
With the DEBUG_INFORMATION_FORMAT flag in the compiler can be told to save the symbol information to a separate file, the .Dsym file. 

When an app is build with `DEPLOYMENT_POSTPROCESSING=Yes`, the crash reports and memory leak reports of the app will not contain method names belonging to the code inside the binary of the app (method names of linked libraries are displayed). Instead the addresses of inside the apps binary are shown in those reports.
If the app was compiled with `DEBUG_INFORMATION_FORMAT=dwarf-with-dsym` then the .Dsym file can be used to translate those addresses back to method names using the `symbolicator` tool. 

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
leaks [process id] > memory_leak.txt
symbolicator --dsym YourApp.Dsym memory_leak.txt

# Parse the memory leak to json
symbolicator --json memory_leak.txt
```

When the `--json` flag is specified, symbolicator will attempt to parse the output and generate a JSON representation.

## Contributing

Feel free to open a pull request! We love to learn if you find this tool useful.
