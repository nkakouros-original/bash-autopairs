# bash-autopairs
A Bash plugin to automatically add closing pairs when typing in Bash's prompt.

This is useful for people who:
- are tired of typing the closing parts in commands like `command_here "$(other_command "${array[2]}")"`
- may forget to add them

## Limitations
- The plugin will disable the `blink-matching-paren` readline option as [it
  seems](https://lists.gnu.org/archive/html/bug-bash/2019-11/msg00044.html) to
  hijack the closing characters.
- If `BASH_AUTOPAIR_BACKSPACE` is set, the plugin will disable the
  `bind-tty-special-chars` option as it prevents Backspace from being mapped.


## Installation
Download and source the `autopairs.sh` file from within your `.bashrc` file. For
instance:

```bash
# .bashrc file
source ~/.config/bash/autopairs.sh
```

To enable `Backspace`, add the line:

```bash
export BASH_AUTOPAIR_BACKSPACE=1
```

## Usage
Once installed, the "plugin" will automatically insert closing pairs whenever you type the opening part of any of the below parts:

```
""
''
()
[]
{}
```

Escaped characters won't be auto paired to let you compose literals with ease.
Try typing:

```bash
sed "s/\"\'//g"
```

It will also delete pairs using `C-h` and `Baskspace`.

For instance, try typing and then deleting the following:

```bash
echo "$(echo "${var[@]}")"
```

## Author
Nikolaos Kakouros

## License
GPLv3
