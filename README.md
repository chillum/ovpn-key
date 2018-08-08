## ovpn-key: key management for OpenVPN [![Gem Version](https://badge.fury.io/rb/ovpn-key.svg)](http://badge.fury.io/rb/ovpn-key)

This utility is designed as [easy-rsa](https://github.com/OpenVPN/easy-rsa) replacement suitable for one exact use case.

It's basically a wrapper around `openssl` to:
* create a self-signed CA
* create client and server certificates and pack them to ZIP files along with the OpenVPN config
* revoke the certificates
* create a DH keyfile

It supports encrypting `.key` files with a passphrase (there is an option to disable that).

It can be used with a non-self signed CA, just place your `ca.key` and `ca.crt` in the keys directory and skip the `--ca` step.

For now it should be considered experimental and rather undocumented.  
If you're brave, [let me know](https://github.com/chillum/ovpn-key/issues), where the problems are.

### Installation

1. Get [Ruby](https://www.ruby-lang.org/en/documentation/installation/)
2. Run `gem install ovpn-key`

### Usage

1. `ovpn-key --init`
2. edit `ovpn-key.yml` and `openssl.ini`
3. `ovpn-key --ca --dh --server --nopass`
4. add a file with `.ovpn` extension to the directory  
   it should contain every setting except for `cert` and `key`
5. `ovpn-key --client somebody`
6. `ovpn-key --revoke somebody`
