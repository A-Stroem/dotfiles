# yq

## Syntax
`yq <expression> <file>`

## Examples
- `yq '.services' docker-compose.yml`
- `yq '.image = "app:v2"' -i deploy.yml`
