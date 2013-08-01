require 'pathname'
require 'rufus-scheduler'
require 'json'
require 'hashie'

dir = Pathname(__FILE__).parent
$:.unshift(dir) unless $:.include?(dir)

require 'bebot/services/compare_branches'

scheduler = Rufus::Scheduler.new

COMPARISONS = JSON.parse(ENV['BEBOT_COMPARISONS'])

COMPARISONS.each do |payload|
  scheduler.every '10m', first_in:'1s' do |job|
    Bebot::Services::CompareBranches.new(
      repo: payload['repo'], from: payload['from'], to: payload['to']
    ).run
  end
end

$stderr.puts "starting scheduler"
scheduler.join