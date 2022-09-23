[![Run tests](https://github.com/mobile-dev-inc/Symbolicator/actions/workflows/test.yml/badge.svg)](https://github.com/mobile-dev-inc/Symbolicator/actions/workflows/test.yml)

# Symbolicator

The binary code of apps can contain symbol information. With symbol information it is possible look up the function name, method name and / or file and line number belonging to a section of the app binary code.

There is a compiler flag that removes this symbol information from the binary. In Xcode this flag is DEPLOYMENT_POSTPROCESSING called. When set to Yes, the compiler will remove the symbol information, resulting in a smaller binary.
With the DEBUG_INFORMATION_FORMAT flag in the compiler can be told to save the symbol information to a separate file, the .dSYM file. 

When an app is build with the flag `DEPLOYMENT_POSTPROCESSING=Yes`, the method names (called symbols) are not included in the app binary. Crash reports and memory leak reports from the app will not contain the app's method names (method names of linked libraries are displayed).
In place of the method names, the address and "load address" of the binary code that was executed is shown instead. 

If the app was compiled with `DEBUG_INFORMATION_FORMAT=dwarf-with-dsym` then the .dSYM file can be used to translate those addresses back to method names using the `symbolicator` tool. 

## Install

Using homebrew:
```
brew tap mobile-dev-inc/tap
brew install symbolicator
```

## Usage

```
# Symbolicate a crash report
symbolicator --dsym-file YourApp.dSYM YourApp.ips

# Symbolicate a memory leak
leaks [process id] > memory_leak.txt
symbolicator --dsym-file YourApp.dSYM memory_leak.txt

# Symbolicate a legacy crash report
symbolicator --dsym-file YourApp.dSYM YourApp.crash
```

## Contributing

Feel free to open a pull request! We love to learn if you find this tool useful.
