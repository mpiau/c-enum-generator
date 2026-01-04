# Overview

**c-enum-generator** is a small tool written in C23 in order to handle generator C enums based on a TOML configuration file.  

I often rewrite a couple of helper functions alongside my enums and there are 2 ways of doing things:  
- You use macros everywhere to generate the code but you decrease the code readability  
- You write the code yourself but you are at risk of not updating everything correctly when the enum is modified.  

Thus, this tool will help me fix both of these issues by generate a code that is macro-free and will automatically handle enum modifications.

# Documentation

## File configuration

The file configuration is in TOML.  
The extension used is **.enum.toml**  

Important: Syntax is WIP. Could change without any notice.  

```toml
# Required. Must be in PascalCase.
name = "Direction"
# Optional. Specify the underlying type of the enum.
# If not provided, 'int' will be used by default.
type = "uint8_t"
# Optional. Speficy a comment to write above the enum declaration
comment = "Small comment"

# Optional section
[includes]
# List of includes needed for the enum values.
system = ["stdint"]
user   = []
# Includes will be written in alphabetical order (based on ASCII rules)
# For system includes:       #include <{name}.h>\n
# For user-defined includes: #include "{name}.h"\n

# Optional section. Default value is written alongside each option.
[options]
typedef     = true  # Typedef the generated enum. 
nodiscard   = true  # Mark every functions with [[nodiscard]]
header_only = false # Put everything under the header file instead of header + implementation.

# Required section
[enum]
# Optional. Decimal by default. Choose how values will be written.
base = "binary/octal/decimal/hexa/HEXA"

# Required field
members = [
   # name  -> Required. UPPER_SNAKE_CASE
   # value -> Optional. If not given, will have the previous value + 1 or 0 if it's the first.
   # comment -> Optional, written after the value for documentation purposes.
   # desc  -> Optional. If not provided, will return the name with a different case. E.g. "NORTH_WEST" -> "North West".
   { name = "NORTH", value = 0, desc = "That's where Santa Claus lives." },
   { name = "SOUTH" },
   { name = "EAST" },
   { name = "WEST" },
]
```