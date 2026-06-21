# shellcheck shell=bash
# rorcc init --docker — scaffold a Dockerized Rails app with no local Ruby/Rails.
# Only Docker is required on the host. Generates the app inside a throwaway
# container, drops in the generic MySQL Docker stack, then installs the framework.

cmd_init_docker() {
  local target="${1:-}"
  if [ -z "$target" ]; then
    err "usage: rorcc init --docker <project-dir>"
    return 2
  fi

  if ! command -v docker >/dev/null 2>&1; then
    err "Docker not found. Install Docker Desktop (enable WSL integration on Windows)."
    return 1
  fi
  if ! docker info >/dev/null 2>&1; then
    err "Docker daemon not reachable. Start Docker Desktop and retry."
    return 1
  fi

  mkdir -p "$target"
  target="$(cd "$target" && pwd)"
  local name; name="$(basename "$target")"
  local assets="$RORCC_LIB_DIR/docker"

  if [ -f "$target/Gemfile" ]; then
    err "$target already contains a Gemfile — choose an empty directory."
    return 1
  fi

  info "Generating Rails app in a throwaway container (this can take a few minutes)..."
  docker run --rm \
    -v "$target:/output" \
    -v "$assets:/assets:ro" \
    -e ASSETS_DIR=/assets \
    -e "HOST_UID=$(id -u)" \
    -e "HOST_GID=$(id -g)" \
    -e "RAILS_NEW_ARGS=--database=mysql --css=tailwind --javascript=esbuild --skip-git --skip-test" \
    -w /output \
    ruby:3.3-bookworm \
    bash /assets/rails-new.sh

  if [ ! -f "$target/.env" ]; then
    sed "s/^DATABASE_NAME=.*/DATABASE_NAME=$name/" "$assets/.env.example" > "$target/.env"
  fi

  info "Installing the RoR Command Center framework..."
  "$RORCC_HOME/install.sh" "$target"

  info "Building the development image..."
  ( cd "$target" && docker compose build && docker compose run --rm web bundle install )

  # bundle install writes Gemfile.lock as root inside the container; reclaim it.
  docker run --rm -v "$target:/output" -w /output ruby:3.3-bookworm \
    chown -R "$(id -u):$(id -g)" /output

  if [ ! -d "$target/.git" ]; then
    info "Initializing git repository..."
    ( cd "$target" && git init -b main >/dev/null && git add . && \
      git commit -q -m "Bootstrap $name via rorcc init --docker" )
  fi

  printf '\n'
  ok "Done: $target"
  printf '  cd %s\n' "$target"
  printf '  docker compose run --rm web rails db:create db:migrate\n'
  printf '  docker compose up        # -> http://localhost:3000\n'
}
