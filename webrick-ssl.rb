#!/usr/bin/env ruby

# Takes arguments of port and root, binds an SSL webserver on 0.0.0.0
# Examples:
#   ./webrick-ssl.rb # Binds 0.0.0.0:8443, serving local dir
#   ./webrisk-ssl.rb 443 /tmp/docroot # binds 443 to /tmp/docroot

require 'webrick'
require 'webrick/https'
require 'openssl'

port = (ARGV[0] || 8443).to_i
root = (ARGV[1] || '.' ).to_s

# Yes this is not secret any more. :) Don't do this in production.
SERVER_KEY = <<-EOL.gsub(/^\s+/,'')
  -----BEGIN RSA PRIVATE KEY-----
  MIICXQIBAAKBgQDevcKo3Ry+BBIh00GdBjRZYtRef4S58txPu35sAy3AfadZnlLE
  NYVzApSr+XJTAk4jFzHedYLvqxyPFJfe3Ik9ExrvqSzM+BmbiWrlddJrtsz2hT14
  J45iqLFnmxQabnSdicDSWQywrZWVC6FJHtCwEBsuRKvPL6IShQr2eczhIQIDAQAB
  AoGAIuCn2HU3CPHuPOmtfn74N37oLhvdlphWsw1y0Er3IQsL51aJMzwGN2oSCZO3
  uRPFVG1PW7we0pSClkztMvJpcqHjCJ6I4QY5bWtQf1y8KPW/v8MipU3auzpxLRnq
  PbAq4fMtW/H6wQRGEezmX20DNz9U7awrYlKlhOefEbGHUVkCQQD8e6XRQZdndQvh
  o5xy3NUF4mRDxpN5zUs8nSrLPqLLl/Y6uFhvyJjR5YLYMwpOq/NsioNv/piv5OPM
  XH3UxXXXAkEA4dgNyIOxUlDACGxDiuEXHhBm+gH7xEFJ+/W27BbvxJNCH+bSCdQb
  37O1U4EYwptGlDGYsTnyvmiGjd/ITv0RxwJBAMM9/qkFtsX7Hhf7hETSfiyRuAUt
  LufWmCKkSu5mXk9gELmxyjmO/pX5jCgRuBvEHnZF2oQldf822e0zbN63X3sCQFWU
  S1TKIm1wz/PhIo8D0IDB8mOWUNMDcoeZiqFX569zpcD09G5pA873CCUGbF2B/XK2
  gIfXz5Y7gZFNVVgpKY0CQQDzOHVfZgzlKYd8+UZZ23tEOYkf8+3lkqwiWkTr3Tvm
  0rEN+4qqavqXJQIWAlxIN78xMU0OGxiZ2gtvh4jFOr9r
  -----END RSA PRIVATE KEY-----
EOL

SERVER_CRT = <<-EOL.gsub(/^\s+/,'')
  -----BEGIN CERTIFICATE-----
  MIIC7TCCAlYCCQCgXQTQsbh8zjANBgkqhkiG9w0BAQUFADCBujELMAkGA1UEBhMC
  VVMxDjAMBgNVBAgMBVRleGFzMQ8wDQYDVQQHDAZBdXN0aW4xGjAYBgNVBAoMEUNv
  bXByb21pc2VkLCBJbmMuMTswOQYDVQQLDDJEZXBhcnRtZW50IG9mIFB1dHRpbmcg
  UHJpdmF0ZSBLZXlzIG9uIHRoZSBJbnRlcm5ldDESMBAGA1UEAwwJbG9jYWxob3N0
  MR0wGwYJKoZIhvcNAQkBFg5yb290QGxvY2FsaG9zdDAeFw0xNDA0MTAxNjQ5MDBa
  Fw0yNDA0MDcxNjQ5MDBaMIG6MQswCQYDVQQGEwJVUzEOMAwGA1UECAwFVGV4YXMx
  DzANBgNVBAcMBkF1c3RpbjEaMBgGA1UECgwRQ29tcHJvbWlzZWQsIEluYy4xOzA5
  BgNVBAsMMkRlcGFydG1lbnQgb2YgUHV0dGluZyBQcml2YXRlIEtleXMgb24gdGhl
  IEludGVybmV0MRIwEAYDVQQDDAlsb2NhbGhvc3QxHTAbBgkqhkiG9w0BCQEWDnJv
  b3RAbG9jYWxob3N0MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDevcKo3Ry+
  BBIh00GdBjRZYtRef4S58txPu35sAy3AfadZnlLENYVzApSr+XJTAk4jFzHedYLv
  qxyPFJfe3Ik9ExrvqSzM+BmbiWrlddJrtsz2hT14J45iqLFnmxQabnSdicDSWQyw
  rZWVC6FJHtCwEBsuRKvPL6IShQr2eczhIQIDAQABMA0GCSqGSIb3DQEBBQUAA4GB
  AEjnsqIR7uOk4BrciZn9SmeutGVlgRALgeyvjyYlWu875Lk4C5KReYgapqz5g6r4
  Yrpuc/I439RaIlt4oiL1bVyRqnW8iGD7gXBLiPA74xGBk0NJVamQ1NmTk8htNLkj
  LBp3yDrslNCsH9KrPVkNXwMFg1NrzoTvkqLs8iY95Xtn
  -----END CERTIFICATE-----
EOL

pkey = OpenSSL::PKey::RSA.new(SERVER_KEY)
cert = OpenSSL::X509::Certificate.new(SERVER_CRT)

server = WEBrick::HTTPServer.new(
  :Port => port,
  :DocumentRoot => root,
  :SSLEnable => true,
  :SSLVerifyClient => OpenSSL::SSL::VERIFY_NONE,
  :SSLCertificate => cert,
  :SSLPrivateKey => pkey,
  :SSLCertName => [ [ "CN",WEBrick::Utils.getservername ] ],
  :Logger => WEBrick::Log.new($stderr, WEBrick::Log::DEBUG)
)

Signal.trap(2) do
  server.shutdown
end
server.start
