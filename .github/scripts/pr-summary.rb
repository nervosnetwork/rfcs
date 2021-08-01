#!/usr/bin/env ruby

require 'time_ago_in_words'
require_relative 'github-graphql'

ReviewRequestsQuery = GitHubGraphQL::Client.parse <<-GRAPHQL
query($query: String!) { 
  search(query: $query, type: ISSUE, first: 100) {
    nodes {
      ... on PullRequest {
        number
        url
        title
        isDraft
        additions
        deletions
        changedFiles
        createdAt
        updatedAt
        commits {
          totalCount
        }
        reviewDecision
        reviewRequests(last: 100) {
          nodes {
            requestedReviewer {
              __typename,
              ... on User {
                login
              }
            }
          }
        }
        latestReviews(first:100) {
          nodes {
            author {
              login
            }
            state
          }
        }
        author {
          login
        }
      }
    }
  }
}
GRAPHQL

repo_owner = 'nervosnetwork'
repo_name = 'rfcs'
body = []

def pluralize(count, singular, plural)
  if count == 1
    "#{count} #{singular}"
  else
    "#{count} #{plural}"
  end
end

def format_pr(pr)
  commits = pluralize(pr.commits.total_count, 'commit', 'commits')
  changed_files = pluralize(pr.changed_files, 'file', 'files')
  created = Time.parse(pr.created_at).ago_in_words
  updated = Time.parse(pr.updated_at).ago_in_words
  "#{pr.title} (#{commits}, #{changed_files}, +#{pr.additions}-#{pr.deletions}, created #{created}, last updated #{updated}) #{pr.url}"
end

def pr_review_state(pr)
  states = pr.latest_reviews.nodes.group_by(&:state)
  components = []
  if states.include?('APPROVED')
    components << "#{states['APPROVED'].size} approved"
  end
  if states.include?('CHANGES_REQUESTED')
    components << "#{states['CHANGES_REQUESTED'].size} requested changes"
  end
  if states.include?('COMMENTED')
    components << "#{states['COMMENTED'].size} commented"
  end
  if states.include?('DISMISSED')
    components << "#{states['DISMISSED'].size} dismissed"
  end
  if states.include?('PENDING')
    components << "#{states['PENDING'].size} pending"
  end

  components.join(', ') 
end

def author_link(login, repos)
  query = "is:open is:pr author:#{login} #{repos} -review:approved"
  "https://github.com/pulls?q=" + URI.encode_www_form_component(query)
end

def reviewer_link(login, repos)
  query = "is:open is:pr review-requested:#{login} #{repos}"
  "https://github.com/pulls?q=" + URI.encode_www_form_component(query)
end

pr_repos = "repo:#{repo_owner}/#{repo_name}"
open_prs = GitHubGraphQL::Client.query(ReviewRequestsQuery, variables: {
  query: "#{pr_repos} is:pr is:open sort:created-asc"
}).data.search.nodes

if open_prs.size > 0
  pending_author_stats = Hash.new {|h, k| h[k] = 0}
  pending_reviewers_stats = Hash.new {|h, k| h[k] = 0}

  body << "# Pull Requests (#{open_prs.size})\n"

  ready_to_merge, remaining_prs = open_prs.partition do |pr|
    pr.review_decision == 'APPROVED'
  end
  if ready_to_merge.size > 0
    body << "## Ready To Merge (#{ready_to_merge.size})\n"
    ready_to_merge.each do |pr|
      body << "- #{pr.author.login} #{pr.title} #{pr.url}"
    end
    body << ''
  end

  pending_author, remaining_prs = remaining_prs.partition do |pr|
    pr.is_draft || (
      pr.review_decision == 'CHANGES_REQUESTED' &&
      pr.latest_reviews.nodes.map(&:state).include?('CHANGES_REQUESTED')
    )
  end
  if pending_author.size > 0
    body << "## Pending Author (#{pending_author.size})\n"
    pending_author.each do |pr|
      pending_author_stats[pr.author.login] += 1

      if pr.is_draft
        body << "- **DRAFT**: @#{pr.author.login} #{format_pr(pr)}"
      else
        body << "- @#{pr.author.login} #{format_pr(pr)}"
        review_state = pr_review_state(pr)
        if review_state != ''
          body << "    - #{review_state}"
        end
        pending_reviewers = pr.review_requests.nodes.map do |node|
          node.requested_reviewer.login
        end.compact
        if pending_reviewers.size > 0
          pending_reviewers.each do |login|
            pending_reviewers_stats[login] += 1
          end
          body << "    - requested reviews from @#{pending_reviewers.join(' @')}"
        end
      end
    end
    body << ''
  end

  if remaining_prs.size > 0
    body << "## Pending Reviewers (#{remaining_prs.size()})\n"
    remaining_prs.each do |pr|
      body << "- #{pr.author.login} #{format_pr(pr)}"
      review_state = pr_review_state(pr)
      if review_state != ''
        body << "    - #{review_state}"
      end
      pending_reviewers = pr.review_requests.nodes.map do |node|
        node.requested_reviewer&.login
      end.compact
      if pending_reviewers.size > 0
        pending_reviewers.each do |login|
          pending_reviewers_stats[login] += 1
        end
        body << "    - requested reviews from @#{pending_reviewers.join(' @')}"
      end
    end
    body << ''
  end

  if pending_author_stats.size + pending_reviewers_stats.size > 0
    body << "## By Owners\n"
    (pending_author_stats.keys + pending_reviewers_stats.keys).uniq.each do |login|
      body << "- @#{login}"
      if pending_author_stats.include?(login)
        body << "    - #{pluralize(pending_author_stats[login], 'pr', 'prs')} to update #{author_link(login, pr_repos)}"
      end
      if pending_reviewers_stats.include?(login)
        body << "    - #{pluralize(pending_reviewers_stats[login], 'pr', 'prs')} to review #{reviewer_link(login, pr_repos)}"
      end
    end
    body << ''
  end

  body << ''
end

puts body.join("\n")

