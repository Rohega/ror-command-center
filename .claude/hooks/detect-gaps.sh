#!/bin/bash
# RoR Command Center — detect documentation gaps for Rails projects

echo "=== Documentation Gap Check ==="

if [ ! -d ".ai" ]; then
    echo "WARN: .ai/ directory missing — framework not installed correctly" >&2
fi

# Rails app without README
if [ -f "Gemfile" ] && [ ! -f "README.md" ]; then
    echo "HINT: Rails project detected without README.md" >&2
fi

# Code without specs directory
if [ -d "app" ] && [ ! -d "spec" ] && [ ! -d "test" ]; then
    echo "HINT: Application code exists without spec/ or test/ directory" >&2
fi

exit 0
