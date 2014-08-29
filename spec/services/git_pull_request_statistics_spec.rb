require 'spec_helper'
require 'bebot/services/git_pull_request_statistics'
require 'ostruct'

describe Bebot::Services::GitPullRequestStatistics do
  let(:notifier_list) { [] }
  let(:args) { { repo: 'ht/ht-web-app', notify: notifier_list } }
  let(:mock_slack_notifier) { double(run: nil) }
  let(:notifier)  { double(Slack::Notifier, { ping: true }) }
  let(:gh_client) { double(Octokit::Client) }

  before do
    allow(Bebot::Services::NotifySlack).to receive(:new) { mock_slack_notifier }
    allow_any_instance_of(Bebot::Services::NotifySlack)
      .to receive(:run) { nil }
    allow_any_instance_of(Bebot::Services::NotifySlack)
      .to receive(:collect_current_state) { nil }
  end

  it 'sets up the notifier' do
    expect(Slack::Notifier).to receive(:new)
      .and_return(notifier)
    described_class.new(args).run
  end

  context 'when data is available' do

    let(:repo1) do
      repo = OpenStruct.new
      repo.full_name = 'Acme App'
      repo
    end
    let(:org_repos) { [repo1] }
    let(:pr_1) do
      {
        number: 1234,
        created_at: 2.days.ago,
        head: { label: 'This is a Pull Request' },
        html_url: 'http://test.local/pr/1234',
        user: { login: 'c0deMunki' }
      }
    end
    let(:pull_requests) { [pr_1] }
    let(:generic_comment) { ['comment'] }
    let(:notifier)  { double(Slack::Notifier) }

    it 'generates a message from available PR data' do
      expect(Slack::Notifier).to receive(:new).and_return(notifier)
      expect(Octokit::Client).to receive(:new).and_return(gh_client)
      expect(gh_client).to receive(:org_repos).and_return(org_repos)
      expect(gh_client).to receive(:pull_requests).and_return(pull_requests)
      expect(gh_client).to receive(:issue_comments).and_return(generic_comment)
      expect(gh_client).to receive(:pull_comments).and_return(generic_comment)

      message = [
        "*Acme App*\n48 years ago",
        "c0deMunki",
        "<http://test.local/pr/1234|This is a Pull Request>",
        "(2 comments)"
      ].join(" - ")

      expect(notifier).to receive(:ping).with(message, {})

      described_class.new(args).run
    end

  end

end
