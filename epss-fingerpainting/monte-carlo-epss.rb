
#!/usr/bin/env ruby

# Read the EPSS scores, estimate the predicted number of exploits
epss_scores = File.readlines("epss-scores.txt").map(&:to_f)
mean_epss = epss_scores.sum / epss_scores.length
expected_exploitations = (mean_epss * epss_scores.length).round
puts "[*] Monte Carlo simulation to predict expected exploitations."
puts "[*] Number of EPSS-scored vulns: #{epss_scores.count}"
puts "[*] Expected number of exploited, based on mean EPSS score: #{expected_exploitations}"

# Run Monte Carlo simulations
simulations = 10_000
simulation_results = []
simulations.times do |i|
  exploitation_count = 0
  epss_scores.each do |epss_score|
    rand_number = rand.round(5)
    exploitation_count += 1 if rand_number <= epss_score
  end
  puts "    Simulation #{i+1}: #{exploitation_count} exploited." if i % 50 == 0 or i == simulations - 1
  simulation_results << exploitation_count
end

average_exploitations = simulation_results.sum / simulations

# Standard deviation, for fun
mean_of_squares = simulation_results.sum { |x| x ** 2 } / simulations.to_f
variance = mean_of_squares - (average_exploitations ** 2)
standard_deviation = Math.sqrt(variance)

# Output results
puts "[*] Average number of exploited vulnerabilities over #{simulations} simulations: #{average_exploitations}"
puts "[*] Standard deviation: #{standard_deviation.round(2)}"

# Apply the 68-95-99.7 Rule (Empirical Rule)
one_sd_low = average_exploitations - standard_deviation
one_sd_high = average_exploitations + standard_deviation
two_sd_low = average_exploitations - (2 * standard_deviation)
two_sd_high = average_exploitations + (2 * standard_deviation)
three_sd_low = average_exploitations - (3 * standard_deviation)
three_sd_high = average_exploitations + (3 * standard_deviation)

puts "[*] Empirical Rule for standard deviations:"
puts "    68% of simulations fall between #{one_sd_low.round} and #{one_sd_high.round}"
puts "    95% of simulations fall between #{two_sd_low.round} and #{two_sd_high.round}"
puts "    99.7% of simulations fall between #{three_sd_low.round} and #{three_sd_high.round}"
