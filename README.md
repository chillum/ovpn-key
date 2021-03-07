## ovpn-key: key management for OpenVPN [![Gem Version](https://badge.fury.io/rb/ovpn-key.svg)](http://badge.fury.io/rb/ovpn-key)

This utility is designed as [easy-rsa](https://github.com/OpenVPN/easy-rsa) replacement suitable for one exact use case.

It's basically a wrapper around `openssl` to:
* create a self-signed CA
* create client and server certificates and pack them to ZIP files along with the OpenVPN config
* revoke the certificates
* create a DH keyfile

It supports encrypting `.key` files with a passphrase (there is an option to disable that).

It can be used with a non-self signed CA, just place your `ca.key` and `ca.crt` in the keys directory and skip the `--ca` step.

It can be used to manage a non-OpenVPN CA, in that case `--zip` and `--static` steps will be useless, but all others will work.

OpenVPN static keys are supported partially, as they should be used for `tls-auth`/`tls-crypt` only.
Please note that they are not encrypted regardless of `--nopass` option.

For now this utility should be considered experimental and rather undocumented.  
If you're brave, [let me know](https://github.com/chillum/ovpn-key/issues), where the problems are.

### Installation

1. Get [Ruby](https://www.ruby-lang.org/en/documentation/installation/)
2. Run `gem install ovpn-key`

### Usage

1. `ovpn-key --init`
2. edit `ovpn-key.yml` and `openssl.ini`
3. `ovpn-key --ca --dh`
4. `ovpn-key --server --nopass`
5. `ovpn-key --client somebody [--nopass]`
6. `ovpn-key --revoke somebody`
7. `ovpn-key --static` (generates `ta.key`)
8. add a file with `.ovpn` extension to the directory  
   it should contain every setting except for `cert` and `key`
9. `ovpn-key --zip somebody-else [--nopass]`

### Configuration

Most of configuration is done in `open-vpn.key` and `openssl.ini` files in the directory.

ovpn-key also processes `~/.ovpn-key.yml` file, for now it has only one possible setting:
```yaml
cd: ~/some/path
```

This setting is used as a default directory if:
1. current directory does not have `ovpn-key.yml`
2. `--init` is not specified

If you specify the default directory, you don't need to travel to it every time you want to launch `ovpn-key`, i.e. you can use it from your home directory or any other, as long as requirements above are met.
