# *callstack_parser*

----
## Info
Decodes process maps for specific backtrace and package with debug symbols (package number must correspond to backtrace).
Note that this tool can also be used to translate addresses using unstripped library (in addition to debug symbols package and / or single debug file) - just load unstripped lib as single debug file.
Can load addresses offset when provided with core dump (backtrace is still required).
Finds relevant addresses via provided prefix and suffix, recognizes corresponding libs and their debug symbol files, translates it. 
Also demangles c++ symbols.

#### Requirements
**callstack_parser** to run  requires *addr2line* and *c++filt* from `binutils` package,
as well *dialog* from `dialog` package. 
It will check for these dependencies and install them when allowed. If you want to do it yourself anyways, issue
```sh
$ sudo apt install -y --no-install-recommends binutils
$ sudo apt install -y --no-install-recommends dialog
```

----
## Prepare
1. The **backtrace**
It can be any text input, not limited directly to the lines with the callstack. You can provide it in three ways:
	- Paste contents of the file directly as user input (all at once).
	- Provide path to text file.
	- Select the file via GUI file manager.

2. The **core** dump file (OPTIONAL)
Memory map is used to load offset values for addresses from the backtrace - provided your client / device vendor doesn't already calculate absolute values with their signal handler, when printing the callstack.
It should be a plaintext file, where rows with offset values are formatted as follows
```address_start-address_end xxx permission_bit xxx lib_name```
You can provide it in three ways:
	- Paste contents of the file directly as user input (all or part, at once).
	- Provide path to text file.
	- Select the file via GUI file manager.

3. The **prefix** 
The script recognizes addresses in a format specified by user input and loads them. Special characters (**+(^** etc.) are allowed. You can either:
	- Select the default prefix.
	- Input custom prefix.

4. The **suffix** 
The script recognizes addresses in a format specified by user input and loads them. Special characters (**+(^** etc.) are allowed. You can either:
	- Select the default suffix.
	- Input custom suffix.

5. The **offset** (OPTIONAL)
Single value only (correct for single lib), it is an alternative to loading the core dump. 
Optional, it is used to load offset values for addresses from the backtrace - provided your client / device vendor doesn't already calculate absolute values with their signal handler, when printing the callstack.
The script can calculate the target address by subtracting the offset value from input address value. Default offset is 0 (none). You can either:
	- Select the default suffix.
	- Input custom suffix.

	Note: offset input by hand (value other than 0) works for single lib only. Some of the vendors (eg. MTK/TPV) provides backtraces with addresses already properly calculated (taking current offset into account).

6. The **package** with debug symbols
If not yet extracted, the script will try and extract it.
Naming convention for it usually is "xxx-debug-symbols". Package build number must be the same as for the SDK for which the backtrace has been provided. You can provide the package in two ways:
	- Provide path to the file.
	- Select the file via GUI file manager.

Note that this tool can also be used to translate addresses using unstripped library (in place of debug symbols package and / or single debug file) - just load unstripped lib as single debug file.

----
## Usage

Program can be run in interacive mode (default), with the usage of select run options, or any combination of the above.

### 1. Interactive
Run 
```sh
./callstack_parser.sh
```
- or 
  ```sh 
  bash callstack_parser.sh
  ```

  when no execute permissions are granted
  
and follow the instructions.
 
### 2. Run options 
Optional.

```sh
./callstack_parser.sh --option
```

where *--option* is:
* `-b`, `--backtrace` `"`*/path/log.txt*`"`
* `-p` , `--prefix` `"`*abc*`"`
* `-s` , `--suffix` `"`*abc*`"`
* `-o` , `--offset` `"`*abc*`"`
  * offset value other than 0 works as intended for single lib only
* `-m`, `--symbols` `"`*/path/file.debug*`"`
  * this flag is optional - provides the direct path to symbols for single library only
  * alternatively, you can just load unstripped lib
* `-y`, `--symbols-package` `"`*/path/xxx-debug-symbols*`"`
* `-c`, `--core` `"`*/path/core_dump*`"`
* `-h`, `--help`

### 3. Combined
Run the script with less than 3 flags (for files listed in Prepare section) provided.

### 4. Manual mode
Specify the variables in the script itself (first few lines of the script).

----
## Additional info

1. Navigate in GUI file manager with ARROWS, SPACE to autocomplete, TAB to change focus targets, ENTER to confirm.