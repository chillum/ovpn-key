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
# rubocop:disable Naming/MethodParameterName
def sign_key(type, cn, password)
  # rubocop:enable Naming/MethodParameterName
  certname = type == 'ca' ? 'ca' : cn
  key = OpenSSL::PKey::RSA.new File.read("#{certname}.key"), password
  subj = OpenSSL::X509::Name.new([['CN', cn]] + REQ.to_a)
  serial = begin
    File.read(SERIAL_FILE).to_i
  rescue Errno::ENOENT
    0
  end + 1

  cert = OpenSSL::X509::Certificate.new
  cert.version = 2
  cert.serial = serial
  cert.not_before = Time.now
  cert.not_after =
    Time.now +
    case type
    when 'ca'
      EXPIRE['ca']
    when 'server'
      EXPIRE['server']
    when 'client'
      EXPIRE['client']
      # days to seconds
    end * 86_400
  cert.public_key = key.public_key
  cert.subject = subj
  cert.issuer = OpenSSL::X509::Name.new([['CN', CN_CA]] + REQ.to_a)

  ef = OpenSSL::X509::ExtensionFactory.new nil, cert
  ef.issuer_certificate = cert

  cert.add_extension ef.create_extension('subjectKeyIdentifier', 'hash')
  cert.add_extension ef.create_extension('authorityKeyIdentifier', 'keyid,issuer:always')
  cert.add_extension ef.create_extension('basicConstraints', type == 'ca' ? 'CA:true' : 'CA:false')

  case type
  when 'ca'
    cert.add_extension ef.create_extension('keyUsage', 'cRLSign,keyCertSign')
    cert.sign key, OpenSSL::Digest.new(DIGEST)
  when 'server'
    cert.add_extension ef.create_extension('keyUsage', 'keyEncipherment,digitalSignature')
    cert.add_extension ef.create_extension('extendedKeyUsage', 'serverAuth')
  when 'client'
    cert.add_extension ef.create_extension('keyUsage', 'digitalSignature')
    cert.add_extension ef.create_extension('extendedKeyUsage', 'clientAuth')
  end
  unless type == 'ca'
    ca_key = begin
      OpenSSL::PKey::RSA.new File.read('ca.key'), ask_password('ca')
    rescue OpenSSL::PKey::RSAError
      retry
    end
    cert.sign ca_key, OpenSSL::Digest.new(DIGEST)
  end

  File.open(SERIAL_FILE, 'w') {|f| f.write serial }
  File.open("#{certname}.crt", 'w') {|f| f.write cert.to_pem }
end

def revoke(certname)
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

def update_crl(crl, ca_pass)
  ca_key = OpenSSL::PKey::RSA.new File.read('ca.key'), ca_pass
  crl.last_update = Time.now
  crl.next_update = Time.now + EXPIRE['crl'] * 86_400 # days to seconds
  crl.version = crl.version + 1
  crl.sign(ca_key, OpenSSL::Digest.new(DIGEST))
  File.open(CRL_FILE, 'w') {|f| f.write crl.to_pem }
end

def create_dir(name)
  return if Dir.exist? name

  Dir.mkdir name
  puts "Created directory: #{name}"
end
