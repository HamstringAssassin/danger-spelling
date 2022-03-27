gemfile_updated = !git.modified_files.grep(/Gemfile/).empty?

# Leave warning, if Gemfile changes
warn 'The `Gemfile` was updated' if gemfile_updated

# Rubocop lint
rubocop.lint(
  force_exclusion: true,
  inline_comment: true,
)

system('bundle exec rubocop --auto-correct')

# CHANGELOG CHECKS
changelog.check!

# Undercover Report
undercover.report

# Suggestor
suggester.suggest
