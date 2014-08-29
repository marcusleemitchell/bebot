require 'bebot/config/env'
require 'slack-notifier'
require 'bebot/services/notify_slack'
require 'octokit'
require 'time-lord'
require 'csv'

NOW = Time.now

module Bebot
  module Services
    class GitPullRequestStatistics

      def initialize(repo:nil, notify: %w(log))
        @repo   = repo
        @notify = notify
        @client = Octokit::Client.new(access_token: ENV.fetch('GITHUB_TOKEN'))
        @repos = @client.org_repos('HouseTrip').collect{|repo| repo.full_name}
      end

      def run
        notifier = Slack::Notifier.new(
          ENV.fetch('SLACK_TEAM'), ENV.fetch('SLACK_TOKEN'),
          channel: ENV.fetch('SLACK_CHANNEL'),
          username: ENV.fetch('SLACK_USERNAME')
        )
        notifier.ping(generate_slack_message, notifier_options)
      end

      private

      def generate_slack_message
        message = []

        @repos.each do |repo_name|
          prs = @client.pull_requests(repo_name)

          next if prs.empty?

          message << "*#{repo_name}*"

          prs
          .sort{ |x,y| x[:created_at] <=> y[:created_at] }
          .each do |pull_request|

            msg_part = []
            created = pull_request[:created_at]
            url     = pull_request[:html_url]
            title   = pull_request[:head][:label]
            num     = pull_request[:number]

            comments = []
            comments.concat(@client.issue_comments(repo_name, num))
            comments.concat(@client.pull_comments(repo_name, num))

            msg_part << TimeLord::Period.new(created, NOW).to_words
            msg_part << pull_request[:user][:login]
            msg_part << "<#{url}|#{title}>"
            msg_part << "(#{comments.length} comments)"

            message << msg_part.join(" - ")
          end
        end

        message.join("\n")
      end

      def notifier_options
        icon_url = ENV.fetch('NAG_ICON_URL', nil)
        icon_url.nil? ? {} : { icon_url: icon_url }
      end

    end
  end
end
