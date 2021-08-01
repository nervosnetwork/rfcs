name: Create PR Summary

on:
  schedule:
    - cron: '30 0 * * 1'
  workflow_dispatch: {}

jobs:
  discussion:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - uses: actions/setup-ruby@v1
      with:
        ruby-version: 2.7

    - name: bundle install
      run: cd .github/scripts/ && bundle install

    - name: run ruby script
      id: today
      run: |
        today="$(cd .github/scripts/ && bundle exec ruby today.rb)"
        today="${today//$'%'/%25}"
        today="${today//$'\n'/%0A}"
        today="${today//$'\r'/%0D}"
        echo "::set-output name=today::$today"
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    - name: Get current date
      id: date
      run: echo "::set-output name=date::$(date +'%Y-%m-%d')"

    - uses: octokit/graphql-action@v2.x
      if: ${{ steps.today.outputs.today != '' }}
      with:
        query: |
          mutation createDiscussionWithBody($body: String!) {
            createDiscussion(input: {
              title: "PR Summary ${{ steps.date.outputs.date }}",
              body: $body,
              categoryId: "DIC_kwDOB1Oxh84B-hNl",
              repositoryId: "MDEwOlJlcG9zaXRvcnkxMjI5MjU0NDc=",
            }) {
              discussion {
                url
              }
            }
          }
        body: ${{ toJSON(steps.today.outputs.today) }}

      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
