## ovpn-key: key management for OpenVPN

### Usage

1. `ovpn-key --init`
2. edit `ovpn-key.yml` and `openssl.ini`
3. `ovpn-key --ca --dh --server --nopass`
4. add a file with `.ovpn` extension to the directory  
   it should contain every setting except for `cert` and `key`
5. `ovpn-key --client somebody`
6. `ovpn-key --revoke somebody`
