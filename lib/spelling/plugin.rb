module Danger
  # This is a Danger plugin that wraps the python library pyspelling and some of its usage.
  # The pyspelling results are posted to the pull request as a comment with the spelling mistake, file path &
  # line number where the spelling mistake was found.
  #
  # It has some dependencies that should be installed prior to running.
  #
  # * [pyspelling](https://facelessuser.github.io/pyspelling/)
  # * [aspell](http://aspell.net)
  # * **OR**
  # * [hunspell](http://hunspell.github.io)
  #
  # Your repository will also require a .pyspelling.yml file to be present. This .pyspelling.yml can be basic,
  # but it will require a name and source property. Its advisable to include `expect_match: false` in your test
  # matrix. This will stop pyspelling from generating an error at runtime.
  #
  # There are several ways to use this danger plugin
  #
  # @example execute pyspelling matrix with the name 'test_matrix' on all files modified or
  # added in the given pull request.
  #          spelling.name = "test_matrix"
  #          spelling.check_spelling
  #
  # @see  HammyAssassin/danger-spelling
  # @tags spelling, danger, pyspelling, hunspell, aspell
  #
  #
  # @example execute pyspelling matrix with the name 'test_matrix' on all files modified or added in the given pull
  # request, excluding some specific file names
  #          spelling.ignored_files = ["Gemfile"]
  #          spelling.name = "test_matrix"
  #          spelling.check_spelling
  #
  # @see  HammyAssassin/danger-spelling
  # @tags spelling, danger, pyspelling, hunspell, aspell
  #
  #
  # @example execute pyspelling matrix with the name 'test_matrix' on all files modified or added in the given pull
  # request, excluding some specific file names and excluding some words
  #          spelling.ignored_words = ["HammyAssassin"]
  #          spelling.ignored_files = ["Gemfile"]
  #          spelling.name = "test_matrix"
  #          spelling.check_spelling
  #
  # @see  HammyAssassin/danger-spelling
  # @tags spelling, danger, pyspelling, hunspell, aspell
  #
  class DangerSpelling < Plugin
    # Allows you to ignore certain words that might otherwise be detected as a spelling error.
    # default value is [] when its nil
    #
    # @return   [Array<String>]
    attr_accessor :ignored_words

    # Allows you to ignore certain files that might otherwise be scanned by pyspelling.
    # The default value is [] for when its nil
    #
    # @return   [Array<String>]
    attr_accessor :ignored_files

    # **required** The name of the test matrix in your .pyspelling.yml
    # An exception will be raised if this is not specified in your Danger file.
    #
    # @return [<String>]
    attr_accessor :name

    # Checks the spelling of all files added or modified in a given pull request. This will fail if
    # pyspelling cannot be installed if not installed already. It will fail if `aspell` or `hunspell`
    # are not detected.
    #
    # It will also fail if the required parameter `name` hasn't been specificed in the Danger file.
    #
    #
    # @param [<Danger::FileList>] files **Optional** files to be scanned. Default value is nil. If nil, added and
    # modified files will be scanned.
    #
    # @return [void]
    #
    def check_spelling(files = nil)
      raise 'name must be a valid matrix name in your .pyspelling.yml.' if name.nil? || name.empty?

      check_for_dependancies

      new_files = get_files files
      results_texts = pyspelling_results(new_files)

      spell_issues = results_texts.select { |_, output| output.include? 'Spelling check failed' }

      # Get some metadata about the local setup
      current_slug = env.ci_source.repo_slug

      update_message_for_issues(spell_issues, current_slug) if spell_issues.count.positive?
    end

    #
    #
    # **Internal Method**
    #
    # Updates the message that will eventually be posted as a comment a pull request with
    # a new line for each time the spelling error has been detected.
    #
    # @param [<Hash>] spell_issues the Hash containing the file path & the detected mistakes.
    # @param [<String>] current_slug the repo. eg /hamstringassassin/danger-spelling.
    #
    # @return [Array<String>] an array of messages to be displayed in the PR comment.
    #
    def update_message_for_issues(spell_issues, current_slug)
      message = "### Spell Checker found issues\n\n"

      spell_issues.each do |path, output|
        git_loc = git_check(current_slug, path)

        message << "#### [#{path}](#{git_loc})\n\n"

        message << "Line | Typo |\n "
        message << "| --- | ------ |\n "

        output_array = output.split(/\n/)
        output_array = remove_ignored_words(output_array, path)

        output_array.each do |txt|
          File.open(path, 'r') do |file_handle|
            file_handle.each_line do |path_line|
              message << "#{$INPUT_LINE_NUMBER} | #{txt} \n " if find_word_in_text(path_line, txt)
            end
          end
        end
      end
      markdown message
    end

    #
    #
    # **Internal Method**
    #
    # splits a line of text up and checks if the spelling error is a match.
    #
    # @param [<String>] text the string to be split and checked.
    # @param [<String>] word the word to find in text.
    #
    # @return [<Bool>] if the word is found.
    #
    def find_word_in_text(text, word)
      val = false
      line_array = text.split
      line_array.each do |array_item|
        array_item = array_item[0...array_item.size - 1] if array_item[-1] == '.'
        if array_item.strip == word.strip
          val = true
          val
        end
      end
      val
    end

    #
    #
    # **Internal Method**
    #
    # Runs pyspelling on the test matrix name provided with any files given.
    #
    # @param [<Danger::FileList>] new_files a list of files provided to scan with pyspelling.
    #
    # @return [Hash] returns a hash of the file scanned and any spelling errors found.
    #
    def pyspelling_results(new_files)
      results_texts = {}
      new_files.each do |file|
        file_result = `pyspelling --name '#{name}' --source '#{file}'`
        results_texts[file] = file_result
      end
      results_texts
    end

    #
    #
    # **Internal Method**
    #
    # Check on the git service used. Will raise an error if using bitbucket as it currently doesnt support that.
    #
    # @param [<String>] current_slug the current repo slug. eg. hamstringassassin/danger-spelling.
    # @param [<String>] path path to file.
    #
    # @return [<String>] full path to file including branch.
    #
    def git_check(current_slug, path)
      if defined? @dangerfile.github
        "/#{current_slug}/tree/#{github.branch_for_head}/#{path}"
      elsif defined? @dangerfile.gitlab
        "/#{current_slug}/tree/#{gitlab.branch_for_head}/#{path}"
      else
        raise 'This plugin does not yet support bitbucket'
      end
    end

    #
    #
    # **Internal Method**
    #
    # Check for dependencies. Raises exception if pyspelling, hunspell or aspell are not installed.
    #
    # @return [Void]
    #
    def check_for_dependancies
      raise 'pyspelling is not in the users PATH, or it failed to install.' unless pyspelling_installed?

      raise 'aspell or hunspell must be installed in order for pyspelling to work.' unless aspell_hunspell_installed?
    end

    #
    #
    # **Internal Method**
    #
    # Checks if a given line can be ignored if it contains expected pyspelling output.
    #
    # @param [<String>] text the text to check.
    # @param [<String>] file_path the file path to check.
    #
    # @return [<Bool>] if the line can be ignored.
    #
    def ignore_line(text, file_path)
      text.strip == 'Misspelled words:' ||
        text.strip == "<text> #{file_path}" ||
        text.strip == '!!!Spelling check failed!!!' ||
        text.strip == '--------------------------------------------------------------------------------' ||
        text.strip == ''
    end

    #
    #
    # **Internal Method**
    #
    # Removes some standard words in the pyspelling results.
    # Words provided in `ignored_words` will also be removed from the results array.
    #
    # @param [<Array>] spelling_errors Complete list of spelling errors.
    # @param [<String>] file_path file path.
    #
    # @return [<Array>] curated list of spelling errors, excluding standard and user defined words.
    #
    def remove_ignored_words(spelling_errors, file_path)
      spelling_errors.delete('Misspelled words:')
      spelling_errors.delete("<text> #{file_path}".strip)
      spelling_errors.delete('!!!Spelling check failed!!!')
      spelling_errors.delete('--------------------------------------------------------------------------------')
      spelling_errors.delete('')
      ignored_words.each do |word|
        spelling_errors.delete(word)
      end
      spelling_errors
    end

    #
    #
    # **Internal Method**
    #
    # Checks of pyspelling is installed.
    #
    # @return [<Bool>]
    #
    def pyspelling_installed?
      'which pyspelling'.strip.empty? == false
    end

    #
    #
    # **Internal Method**
    #
    # Checks if aspell is installed.
    #
    # @return [<Bool>]
    #
    def aspell_installed?
      'which aspell'.strip.empty? == false
    end

    #
    #
    # **Internal Method**
    #
    # Checks if Hunspell is installed.
    #
    # @return [<Bool>]
    #
    def hunspell_installed?
      'which hunspell'.strip.empty? == false
    end

    #
    #
    # **Internal Method**
    #
    # checks if aspell and hunspell are installed.
    #
    # @return [<Bool>]
    #
    def aspell_hunspell_installed?
      aspell_installed? && hunspell_installed?
    end

    #
    #
    # **Internal Method**
    #
    # Gets a file list of the files provided or finds modified and added files to scan.
    # If files are provided via `ignored_files` they will be removed from the final returned
    # list.
    #
    # Will raise an exception if no files are found.
    #
    # @param [<Danger::FileList>] files FileList to scan. Can be nil.
    #
    # @return [<Danger::FileList>] a FileList of files found.
    #
    def get_files(files)
      # Use either the files provided, or the modified & added files.
      found_files = files ? Dir.glob(files) : (git.modified_files + git.added_files)
      puts "found files...#{found_files.class}"
      raise 'No files found to check' if found_files.nil?

      ignored_files.each do |file|
        found_files.delete(file)
      end
      found_files
    end
  end
end
