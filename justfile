set shell := ["/bin/bash", "-euo", "pipefail", "-c"]

default: build

build:
  swift build

build-release:
  swift build -c release

bundle:
  ./scripts/bundle-app.sh debug

bundle-release:
  ./scripts/bundle-app.sh release

run:
  swift run

test:
  swift test -c release
