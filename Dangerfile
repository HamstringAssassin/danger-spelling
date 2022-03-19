gemfile_updated = !git.modified_files.grep(/Gemfile/).empty?

# Leave warning, if Gemfile changes
warn 'The `Gemfile` was updated' if gemfile_updated

# Rubocop lint
rubocop.lint

# CHANGELOG CHECKS
changelog.check!
