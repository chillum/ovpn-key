# frozen_string_literal: true

def check_crt(filename)
  %w[key crt].each {|ext|
    abort "#{filename}.#{ext} already exists, exiting" if File.exist? "#{filename}.#{ext}"
  }
end

def check_client(name)
  abort 'Error: client should have an alphanumeric name' unless name
  check_crt(name)
end

def exe(cmd)
  system(cmd) || abort("error executing: #{cmd}")
end

def ask_password(name)
  password = ''
  loop do
    print "Enter password for #{name}.key: "
    password = $stdin.noecho(&:gets).chomp
    puts # trailing newline
    break unless password.empty?
  end
  password
end

def unencrypt_ca_key
  OpenSSL::PKey::RSA.new File.read('ca.key'), ask_password('ca')
rescue OpenSSL::PKey::RSAError
  retry
end

def gen_and_sign(type, certname, password)
  gen_key(certname, password)
  sign_key(type, certname, password)
end

def gen_key(certname, password)
  key = OpenSSL::PKey::RSA.new(KEY_SIZE)
  File.open("#{certname}.key", 'w') do |f|
    f.write password ? key.to_pem(OpenSSL::Cipher.new(ENCRYPT), password) : key
  end
end

# type is one of: 'ca', 'server', 'client'
def sign_key(type, cn, password)
  certname = type == 'ca' ? 'ca' : cn
  key = OpenSSL::PKey::RSA.new File.read("#{certname}.key"), password
  serial = new_serial
  cert = gen_cert(type, cn, key, serial)

  ca_key = type == 'ca' ? key : unencrypt_ca_key
  cert.sign ca_key, OpenSSL::Digest.new(DIGEST)

  File.open(SERIAL_FILE, 'w') {|f| f.write serial }
  File.open("#{certname}.crt", 'w') {|f| f.write cert.to_pem }
end

def gen_cert(type, cn, key, serial)
  cert = basic_cert(cn)
  cert.public_key = key.public_key
  cert.serial = serial

  customize_cert(cert, type)
end

# rubocop:disable Metrics/AbcSize
def basic_cert(cn)
  # rubocop:enable Metrics/AbcSize
  subj = OpenSSL::X509::Name.new([['CN', cn]] + REQ.to_a)
  cert = OpenSSL::X509::Certificate.new

  cert.version = 2
  cert.subject = subj
  cert.issuer = OpenSSL::X509::Name.new([['CN', CN_CA]] + REQ.to_a)
  cert.not_before = Time.now
  cert.not_after = Time.now + EXPIRE[type] * 86_400 # days to seconds

  cert
end

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
def customize_cert(cert, type)
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  ef = OpenSSL::X509::ExtensionFactory.new nil, cert
  ef.issuer_certificate = cert

  cert.add_extension ef.create_extension('subjectKeyIdentifier', 'hash')
  cert.add_extension ef.create_extension('authorityKeyIdentifier', 'keyid,issuer:always')
  cert.add_extension ef.create_extension('basicConstraints', type == 'ca' ? 'CA:true' : 'CA:false')

  case type
  when 'ca'
    cert.add_extension ef.create_extension('keyUsage', 'cRLSign,keyCertSign')
  when 'server'
    cert.add_extension ef.create_extension('keyUsage', 'keyEncipherment,digitalSignature')
    cert.add_extension ef.create_extension('extendedKeyUsage', 'serverAuth')
  when 'client'
    cert.add_extension ef.create_extension('keyUsage', 'digitalSignature')
    cert.add_extension ef.create_extension('extendedKeyUsage', 'clientAuth')
  end

  cert
end

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
def revoke(certname)
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  crl = OpenSSL::X509::CRL.new(File.read(CRL_FILE))
  cert = OpenSSL::X509::Certificate.new(File.read("#{certname}.crt"))
  revoke = OpenSSL::X509::Revoked.new.tap {|rev|
    rev.serial = cert.serial
    rev.time = Time.now
  }
  crl.next_update = Time.now + EXPIRE['crl'] * 86_400 # days to seconds
  crl.add_revoked(revoke)
  begin
    update_crl(crl, ask_password('ca'))
  rescue OpenSSL::PKey::RSAError
    retry
  end

  %w[crt key].each {|ext| File.delete "#{certname}.#{ext}" }
end

def gen_crl(ca_pass)
  return if File.exist? CRL_FILE

  crl = OpenSSL::X509::CRL.new
  crl.issuer = OpenSSL::X509::Name.new([['CN', CN_CA]] + REQ.to_a)
  update_crl(crl, ca_pass)
end

# rubocop:disable Metrics/AbcSize
def update_crl(crl, ca_pass)
  # rubocop:enable Metrics/AbcSize
  ca_key = OpenSSL::PKey::RSA.new File.read('ca.key'), ca_pass
  crl.last_update = Time.now
  crl.next_update = Time.now + EXPIRE['crl'] * 86_400 # days to seconds
  crl.version = crl.version + 1
  crl.sign(ca_key, OpenSSL::Digest.new(DIGEST))
  File.open(CRL_FILE, 'w') {|f| f.write crl.to_pem }
end

def new_serial
  begin
    File.read(SERIAL_FILE).to_i
  rescue Errno::ENOENT
    0
  end + 1
end

def create_dir(name)
  return if Dir.exist? name

  Dir.mkdir name
  puts "Created directory: #{name}"
end
