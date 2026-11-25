#!/usr/bin/env python3
"""Private credential lookup for git; secret values go only to git's askpass pipe."""
import json
import os
from pathlib import Path
import sys
import urllib.parse

config = json.loads(Path(os.environ['SYNDICATE_RELEASE_CONFIG']).read_text())['github']
if 'username' in sys.argv[1].lower():
    print(config['username'])
else:
    for line in Path(config['credentials_file']).expanduser().read_text().splitlines():
        value = urllib.parse.urlsplit(line)
        if value.hostname == 'github.com' and value.username == config['username'] and value.password:
            print(urllib.parse.unquote(value.password))
            break
    else:
        raise SystemExit(1)
