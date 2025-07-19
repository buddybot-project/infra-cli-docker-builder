### [RU](./README.ru.md)

```bash
Usage: ./build.sh [[<name>][:<tag>] | [--name[=<name>] --tag[=<tag>]]] [--deploy] [--registry=<url>]

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
  ./build.sh                          # Auto-detect everything
  ./build.sh :v1.0                    # Auto-name with custom tag
  ./build.sh --deploy                 # Build and push to auto-detected registry
  ./build.sh --name=myapp --tag=test  # Explicit name and tag
  ./build.sh --registry=registry.example.com --deploy  # Use custom registry

Image naming rules:
  1. If no name specified, uses Git project path (e.g. 'group/project')
  2. If registry detected, prepends registry URL
  3. Tag defaults to 'latest' if not specified

```
