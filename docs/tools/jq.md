# jq

## Syntax
`jq [options] <filter> [file]`

## Examples
- `jq '.' data.json`
- `jq '.items[] | .name' data.json`
- `curl ... | jq -r '.id'`
