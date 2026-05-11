#!/usr/bin/env ruby

# NetHack donation calculator
#
# Calculates approximate 50% and guaranteed (100%) donation thresholds
# for clairvoyance and protection in NetHack 5.0.0.
#
# If --gold is supplied, calculates the odds of obtaining:
#   - clairvoyance
#   - protection
#
# Usage examples:
#   ruby nethack_donate.rb -x 10
#   ruby nethack_donate.rb -x 11 -c 1
#   ruby nethack_donate.rb -x 13 -g 3125
#   ruby nethack_donate.rb -x 14 -g 5500

require 'optparse'

def parse_options
  options = {
    xp: nil,
    cheapskate: 0,
    gold: nil
  }

  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: nethack_donate.rb [options]'

    opts.on('-x LEVEL', '--xp LEVEL',
            '-l LEVEL', '--level LEVEL',
            Integer,
            'Current/max XP level') do |v|
      options[:xp] = v
    end

    opts.on('-c N', '--cheapskate N',
            Integer,
            'Cheapskate penalty count (default: 0)') do |v|
      options[:cheapskate] = v
    end

    opts.on('-g GOLD', '--gold GOLD',
            Integer,
            'Gold available for donation') do |v|
      options[:gold] = v
    end
  end

  parser.parse!

  abort 'Error: XP level must be an integer specified with -x/-l/--xp/--level' if options[:xp].nil?
  abort 'Error: XP level must be between 1 and 30.' if options[:xp] < 1 || options[:xp] > 30
  abort 'Error: Cheapskate level must be zero or more' if options[:cheapskate].negative?

  options
end

options = parse_options

xp = options[:xp]
cheapskate = options[:cheapskate]
gold = options[:gold]

# Baseline range:
#
# ((150..250) + 40*cheapskate) * XP
#
# There are always 101 equally likely rolls.

base_low_roll  = 150 + (40 * cheapskate)
base_high_roll = 250 + (40 * cheapskate)

base_mid = (200 + (40 * cheapskate)) * xp
base_max = base_high_roll * xp

clair_50  = base_mid
clair_100 = base_max

prot_50  = 2 * base_mid
prot_100 = 2 * base_max

puts
puts 'NetHack 5.0.0 Donation Calculator'
puts '---------------------------------'
puts "XP level:           #{xp}"
puts "Cheapskate count:   #{cheapskate}"
puts

if gold.nil?

  puts 'Clairvoyance:'
  puts "  ~50% threshold:   #{clair_50} zm"
  puts "  100% threshold:   #{clair_100} zm"
  puts

  puts 'Protection:'
  puts "  ~50% threshold:   #{prot_50} zm"
  puts "  100% threshold:   #{prot_100} zm"
  puts

else

  puts "Gold available:     #{gold} zm"
  puts

  if gold >= prot_100
    puts 'You already have enough gold for guaranteed protection.'
    puts "Donate #{prot_100} zm."
    puts
    exit 0
  end

  # Clairvoyance odds
  #
  # Need:
  #   gold >= baseline
  #
  # baseline roll is uniform from low_roll..high_roll inclusive

  clair_max_roll = gold / xp
  clair_successes =
    [[clair_max_roll - base_low_roll + 1, 0].max, 101].min

  clair_pct = (clair_successes.to_f / 101.0) * 100.0

  # Protection odds
  #
  # Need:
  #   gold >= 2 * baseline
  #
  # => baseline <= gold / 2

  prot_max_roll = gold / (2 * xp)
  prot_successes =
    [[prot_max_roll - base_low_roll + 1, 0].max, 101].min

  prot_pct = (prot_successes.to_f / 101.0) * 100.0

  puts 'Clairvoyance chance:'
  puts "  #{clair_successes}/101 "\
       "(#{format('%.2f', clair_pct)}%)"
  puts

  puts 'Protection chance:'
  puts "  #{prot_successes}/101 "\
       "(#{format('%.2f', prot_pct)}%)"
  puts

  if prot_successes == 0 && clair_successes == 0
    puts 'Donation is too small to reliably obtain either effect.'
    puts
  elsif prot_successes == 0
    puts 'This donation can only reach the clairvoyance tier.'
    puts
  elsif prot_successes < 101
    puts 'This donation may result in either clairvoyance or protection.'
    puts
  end
end
