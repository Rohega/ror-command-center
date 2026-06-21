#!/usr/bin/env bash
# Runs INSIDE a throwaway ruby:3.3 container (not on the host).
# Generates a fresh Rails app in the mounted /output dir, drops in the generic
# Docker dev assets, then wires the mandatory RSpec test stack
# (.ai/standards/project-bootstrap.md). The framework (.ai/.cursor/AGENTS.md) is
# added afterwards on the host via install.sh.
set -euo pipefail

ASSETS="${ASSETS_DIR:-/assets}"

echo "==> rails-new (docker): output=$(pwd)"
if [[ -f Gemfile ]]; then
  echo "ERROR: a Gemfile already exists in $(pwd). Use an empty directory."
  exit 1
fi

apt-get update -qq
apt-get install -y -qq build-essential default-libmysqlclient-dev git curl ca-certificates
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y -qq nodejs

gem install rails bundler --no-document

echo "==> rails new . ${RAILS_NEW_ARGS:-}"
rails new . ${RAILS_NEW_ARGS:---database=mysql --css=tailwind --javascript=esbuild --skip-git --skip-test}

echo "==> Adding generic Docker dev assets..."
cp "${ASSETS}/Dockerfile.dev" .
cp "${ASSETS}/docker-compose.yml" .
cp "${ASSETS}/.dockerignore" .
cp "${ASSETS}/database.yml" config/database.yml
mkdir -p bin
cp "${ASSETS}/docker-entrypoint.sh" bin/
chmod +x bin/docker-entrypoint.sh

# RSpec is mandatory per .ai/standards/project-bootstrap.md. Set it up here so the
# generated app ships with the test stack already wired (instead of Minitest).
# Non-fatal: a failure here must not abort the whole bootstrap.
echo "==> Setting up RSpec test stack (project-bootstrap standard)..."
{
  bundle add rspec-rails factory_bot_rails --group "development, test" --skip-install &&
  bundle add simplecov --group "test" --skip-install &&
  bundle install &&
  bundle exec rails generate rspec:install &&
  mkdir -p spec/factories &&
  ruby -i -pe '$_ += "    config.generators do |g|\n      g.test_framework :rspec, fixtures: true, view_specs: false, helper_specs: false, routing_specs: false\n      g.fixture_replacement :factory_bot, dir: \"spec/factories\"\n    end\n" if /class Application < Rails::Application/' config/application.rb
} || echo "WARN: RSpec setup step failed — configure it manually per .ai/standards/project-bootstrap.md"

# rails new runs as root inside the container, so the generated files are owned
# by root on the host. Hand them back to the invoking user so host-side tools
# (install.sh, git) can write to them.
if [[ -n "${HOST_UID:-}" && -n "${HOST_GID:-}" ]]; then
  echo "==> Restoring ownership to ${HOST_UID}:${HOST_GID}..."
  chown -R "${HOST_UID}:${HOST_GID}" /output
fi

echo "==> Rails bootstrap complete."
