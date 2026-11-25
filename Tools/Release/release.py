#!/usr/bin/env python3
"""Syndicate iOS release entry point. See README.md; machine configuration is private."""
import sys
sys.dont_write_bytecode = True
from syndicate_release.cli import main

if __name__ == '__main__':
    raise SystemExit(main())
