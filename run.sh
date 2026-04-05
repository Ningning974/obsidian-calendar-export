#!/bin/bash

# Calendar Export Wrapper Script
# This script runs the Swift calendar export tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_SCRIPT="$SCRIPT_DIR/export-calendar.swift"

# Parse and pass arguments to Swift script
"$SWIFT_SCRIPT" "$@"
