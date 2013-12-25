#!/usr/bin/env ruby

# Just goofing around with simplistic data gathering given a BitCoin
# wallet...

module BitCoin
  class Wallet

    ADDRESS_REGEX = /\x04name\x22[13][A-Za-z0-9]{26,33}/

    attr_reader :addresses

    def initialize(fname="./wallet.dat")
      @data = File.open(fname, "rb") {|f| f.read f.stat.size}
      extract_addresses
      return self
    end

    def to_s
      "#<#{self.class.to_s}:#{self.object_id}>"
    end

    def extract_addresses
      @addresses ||= @data.scan(ADDRESS_REGEX).map {|x| x[6,34]}
    end

    def blockchain_urls
      url_prefix = "https://www.biteasy.com/blockchain/addresses/"
      @addresses.map {|x| url_prefix + x}
    end

  end
end


