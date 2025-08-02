# Thoki (Linux Variant) - Simple IOC and YARA Scanner


### What's already implemented

- System reconnaissance (system and hardware information for the log)
- CPU Limiting
- Logging and formatting of the different log outputs
- File system walk
- File time evaluation (MAC timestamps)
- Exclusions based on file characteristics
- IOC initialization - hash values
- IOC matching on files (hashes)
- YARA rule initialization, syntax checks, and error handling
- YARA scanning of files
- YARA scanning of process memory 

### What's still to do

- IOC initialization - file patterns
- IOC initialization - C2 patterns (FQDN, IP)
- IOC matching on files (file patterns)
- C2 IOC matching (process connections)
- File system walk exceptions: network drivers, mounted drives etc.
- Custom exclusions (regex on file path)
- Release workflows (automatically build and provide as release)

# Setup Build Environment

## Build

```bash
sudo ./build.sh
```

## Test Run

```bash
chmod +x ./thoki
sudo ./thoki
```

## Usage

```
Usage: thoki [OPTIONS]

THOKI YARA and IOC Scanner

Options:
  -m, --max-file-size         Maximum file size to scan (default: 10000000)
  -s, --show-access-errors    Show all file and process access errors
  -c, --scan-all-files        Scan all files regardless of their file type / extension
  -a, --scan-all-drives       Scan all drives (including mounted drives, usb drives, cloud drives)
  -d, --debug                 Show debugging information
  -t, --trace                 Show very verbose trace output
  -n, --noprocs               Don't scan processes
  -o, --nofs                  Don't scan the file system
  -f, --folder                Folder to scan
  -p, --cpu-limit             Limit CPU usage percentage (e.g. 20 for 20%)
  -h, --help                  Show this help message.
```
# Remarks

Deployment on Fresh Systems:

On the system, place the following in the same directory:

•	The statically built loki ELF binary

•	The "signatures" folder (with the content of the signature-base inside)

# Screenshots

![Screenhot of Thoki](https://github.com/BobaBubbles/Thoki2/blob/master/screens/thoki-linux.png)

# License and Credits

Loki2 - Simple IOC Scanner Copyright (c) 2015 Florian Roth

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/

This repository was forked from Loki (https://github.com/Neo23x0/Loki2) with modifications and improvements by: Melvin Teo, Micah Chia, Tan De Jun, Javier Tan, Lim Jek Qi
