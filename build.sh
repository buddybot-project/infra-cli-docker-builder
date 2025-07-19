#!/bin/bash

# Default values
NAME=""
TAG=""
DEPLOY=false
REGISTRY=""
AUTO_REGISTRY=true

show_help() {
  cat <<EOF
Usage: $0 [[<name>][:<tag>] | [--name[=<name>] --tag[=<tag>]]] [--deploy] [--registry=<url>]

Build and optionally push Docker image with smart defaults from Git repository.

Options:
  <name>[:<tag>]       Specify image name and tag together (e.g. 'app:latest')
  --name[=<name>]      Specify image name separately
  --tag[=<tag>]        Specify image tag separately
  --deploy             Push image to registry after build
  --registry=<url>     Explicitly set registry URL (default: auto-detected)
  --no-auto-registry   Disable registry auto-detection
  -h, --help           Show this help message

Examples:
  $0                          # Auto-detect everything
  $0 :v1.0                    # Auto-name with custom tag
  $0 --deploy                 # Build and push to auto-detected registry
  $0 --name=myapp --tag=test  # Explicit name and tag
  $0 --registry=registry.example.com --deploy  # Use custom registry

Image naming rules:
  1. If no name specified, uses Git project path (e.g. 'group/project')
  2. If registry detected, prepends registry URL
  3. Tag defaults to 'latest' if not specified
EOF
  exit 0
}

get_git_repo_path() {
  local remote_url
  remote_url=$(git config --get remote.origin.url)

  if [[ "$remote_url" =~ ^git@ ]]; then
    echo "$remote_url" | sed -E 's|^git@[^:]+:||' | sed -E 's|\.git$||'
  elif [[ "$remote_url" =~ ^https?:// ]]; then
    echo "$remote_url" | sed -E 's|^https?://[^/]+/||' | sed -E 's|\.git$||'
  else
    echo "Error: Could not determine Git repository path from remote" >&2
    exit 1
  fi
}

detect_registry() {
  local remote_url=$(git config --get remote.origin.url)
  
  # GitLab detection
  if [[ "$remote_url" =~ gitlab\.com|gitlab\. ]]; then
    echo "registry.gitlab.com"
  # GitHub detection
  elif [[ "$remote_url" =~ github\.com|github\. ]]; then
    echo "ghcr.io"
  # Add other registry detectors as needed
  else
    echo ""
  fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      ;;
    --deploy)
      DEPLOY=true
      shift
      ;;
    --registry=*)
      REGISTRY="${1#*=}"
      AUTO_REGISTRY=false
      shift
      ;;
    --no-auto-registry)
      AUTO_REGISTRY=false
      shift
      ;;
    --name=*)
      NAME="${1#*=}"
      shift
      ;;
    --name)
      NAME=""
      shift
      ;;
    --tag=*)
      TAG="${1#*=}"
      shift
      ;;
    --tag)
      TAG=""
      shift
      ;;
    *:*)
      IFS=':' read -r NAME TAG <<< "$1"
      shift
      ;;
    *)
      NAME="$1"
      TAG=""
      shift
      ;;
  esac
done

# Auto-detect registry if needed
if $AUTO_REGISTRY && [[ -z "$REGISTRY" ]]; then
  REGISTRY=$(detect_registry)
fi

# Получаем чистое имя проекта
if [[ -z "$NAME" ]]; then
  REPO_PATH=$(get_git_repo_path)
  if [[ -n "$REGISTRY" ]]; then
    NAME="$REGISTRY/$REPO_PATH"
  else
    NAME="$REPO_PATH"
  fi
fi

echo "Remote URL: $(git config --get remote.origin.url)"
echo "Parsed REPO_PATH: $REPO_PATH"
echo "Final image name: $NAME:$TAG"

# Set default tag
: "${TAG:=latest}"

# Build image
echo "Building Docker image: $NAME:$TAG"
docker build -t "$NAME:$TAG" .

# Push if --deploy
if $DEPLOY; then
  if [[ -z "$REGISTRY" ]]; then
    echo "Error: No registry specified and could not auto-detect registry" >&2
    exit 1
  fi
  
  echo "Pushing to $REGISTRY..."
  docker push "$NAME:$TAG"
fi
