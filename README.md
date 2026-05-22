IETF BMP Telemetry Message draft.


# Validation

Examples are validated with `yanglint` version 5.7.1 from [libyang](https://github.com/CESNET/libyang).

Regenerate schema trees and validate all examples:
```bash
./validate.sh
```

Single Tree
```bash
yanglint yang/ietf-bmp-telemetry-message@XXXX-XX-XX.yang -f tree --tree-line-length 69 -p deps
```

Full tree validating the schemas
```bash
yanglint -p yang/deps yang/ietf-bmp-telemetry-message@XXXX-XX-XX.yang -f tree --tree-line-length 69
```

Format for Datatracker
```bash
yanglint yang/ietf-bmp-telemetry-message@XXXX-XX-XX.yang -f yang -p yang/deps
cat yang/ietf-bgp-rib-entry@XXXX-XX-XX.yang
cat yang/ietf-bmp-telemetry-message@XXXX-XX-XX.yang
```

Example JSON validation:
```bash
yanglint -e -Y yang/yang-lib-bmptm.xml -p yang examples/ipv4-unicast-loc-rib.json -f json
yanglint -e -Y yang/yang-lib-bmptm.xml -p yang examples/ipv4-unicast-adj-rib-in-pre.json -f json
yanglint -e -Y yang/yang-lib-bmptm.xml -p yang examples/ipv6-unicast-loc-rib.json -f json
yanglint -e -Y yang/yang-lib-bmptm.xml -p yang examples/peer-up-loc-rib.json -f json
```