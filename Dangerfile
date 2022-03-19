gemfile_updated = !git.modified_files.grep(/Gemfile/).empty?

# Leave warning, if Gemfile changes
if gemfile_updated
  warn "The `Gemfile` was updated"
end

# Rubocop lint
rubocop.lint

# CHANGELOG CHECKS
changelog.check!
