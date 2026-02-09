IETF BMP Telemetry Message draft.


# Validation
Examples are validated with `yanglint` version 4.2.2 tool from [libyang](https://github.com/CESNET/libyang)


Single Tree
```shell
$ yanglint yang/ietf-bmp-telemetry-message@2026-01-04.yang -f tree --tree-line-length 69 -p deps
```

Full tree validating the schemas
```bash
yanglint -p yang/deps yang/ietf-bmp-telemetry-message@2026-01-04.yang -f tree --tree-line-length 69
```

Format for Datatracker
```shell
$ yanglint yang/ietf-bmp-telemetry-message@2026-01-04.yang -f yang -p yang/deps
$ cat ietf-bmp-bgp-rib@2026-02-09.yang
$ cat yang/ietf-bmp-bgp-rib-attributes@2026-02-09.yang
$ cat yang/ietf-bmp-bgp-rib-tables@2026-02-09.yang
```

Example JSON validation:
```bash
yanglint -e -Y yang/yang-lib.xml -p yang examples/ipv4-unicast-loc-rib.json -f json
yanglint -e -Y yang/yang-lib.xml -p yang examples/ipv4-unicast-adj-rib-in-pre.json -f json
yanglint -e -Y yang/yang-lib.xml -p yang examples/ipv6-unicast-loc-rib.json -f json
```