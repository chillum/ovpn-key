def check_crt filename
  ['key', 'crt'].each {|ext|
    abort "#{filename}.#{ext} already exists, exiting" if File.exist? "#{filename}.#{ext}"
  }
end

def check_client name
  abort "Error: client should have an alphanumeric name" unless name
  check_crt(name)
end

def exe cmd
  system(cmd) or abort "error executing: #{cmd}"
end

def gen_and_sign type, certname, no_password
  gen_key(certname, no_password)
  sign_key(type, certname, certname)
end

def gen_key certname, no_password
  if no_password
    exe "#{OPENSSL} genrsa -out '#{certname}.key' #{KEY_SIZE}"
  else
    exe "#{OPENSSL} genrsa -#{ENCRYPT} -out '#{certname}.key' #{KEY_SIZE}"
  end
end

def sign_key type, certname, cn
  if certname == 'ca'
    exe "#{OPENSSL} req -new -x509 -key '#{certname}.key' -out '#{certname}.crt' -config #{SSL_CONF} -subj '/CN=#{cn}#{REQ}' -extensions ext.#{type} -days #{CA_DAYS}"
  else
    exe "#{OPENSSL} req -new -key '#{certname}.key' -out '#{certname}.csr' -config #{SSL_CONF} -subj '/CN=#{cn}#{REQ}' -extensions ext.#{type}"
    exe "#{OPENSSL} ca -in '#{certname}.csr' -out '#{certname}.crt' -config #{SSL_CONF} -extensions ext.#{type} -batch"
    File.delete "#{certname}.csr"
  end
end

def gen_crl
  exe "#{OPENSSL} ca -gencrl -out crl.pem -config #{SSL_CONF}"
end

def create_dir name
  unless Dir.exist? name
    Dir.mkdir name
    puts "Created directory: #{name}"
  end
end
