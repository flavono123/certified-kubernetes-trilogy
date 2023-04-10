# Problem 3: Troubleshooting

<details>
<summary>

Write a command to display all namespace names for each line into `root@node-1:$HOME/print_namespaces.sh`, the command should use `kubectl`. </summary>

```sh
$ echo 'kubectl get ns -o jsonpath="{.items[*].metadata.name}" | tr " " "\n"' > /root/print_namespaces.sh
# or
$ echo 'kubectl get ns -o name | sed "s/namespace\///"' > /root/print_namespaces.sh
# or
$ echo 'kubectl get ns -o custom-columns=NAME:.metadata.name --no-headers' > /root/print_namespaces.sh
# or
$ echo 'kubectl get ns -o json | jq -r ".items[].metadata.name"' > /root/print_namespaces.sh
```

</details>

