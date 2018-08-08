## ovpn-key: key management for OpenVPN

### Usage

1. `ovpn-key --init`
2. edit `ovpn-key.yml` and `openssl.ini`
3. `ovpn-key --ca --dh --server --nopass`
4. `ovpn-key --client somebody`
5. `ovpn-key --revoke somebody`
