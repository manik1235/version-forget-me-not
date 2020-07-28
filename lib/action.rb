# frozen_string_literal: true

require 'octokit'

# Fetch and check the version
class Action
  attr_reader :client, :repo

  SEMVER_VERSION =
    /["'](0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?["']/.freeze

  def initialize(owner:, repo_name:, client: nil)
    @client = client || Octokit::Client.new(access_token: ENV['BOT_TOKEN'])
    @repo = "#{owner}/#{repo_name}"
  end

  def version_file_changed?(pull_number)
    client.pull_request_files(repo, pull_number).include?(ENV['VERSION_FILE_PATH'])
  end

  def version_updated?(branch:, trunk: 'master')
    compare_version_arrays(
        fetch_version(ref: branch).split('.').map(&:to_i),
        fetch_version(ref: trunk).split('.').map(&:to_i)
    )
  end

  private

  def fetch_version(ref:)
    content = client.contents(repo, path: ENV['VERSION_FILE_PATH'], query: { ref: ref })
    content.match(SEMVER_VERSION)[0].gsub(/\'/, '')
  end

  # returns true if the branch version is greater than the trunk version
  def compare_version_arrays(branch, trunk)
    index = (0..2).find { |i| branch[i] != trunk[i] }
    branch[index] > trunk[index] if index
  end
end
