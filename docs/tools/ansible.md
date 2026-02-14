# ansible

## Syntax
`ansible <pattern> -m <module> [args]`

## Examples
- `ansible all -m ping`
- `ansible web -m shell -a "uptime"`
- `ansible-playbook site.yml --diff`
