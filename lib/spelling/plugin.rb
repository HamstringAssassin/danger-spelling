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
  # but it will require a name and source property.
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
    # @return void
    #
    def check_spelling(files = nil)
      if name.nil? || name.empty?
        raise 'name must be a valid matrix name in your .pyspelling.yml.'
      end

      check_for_dependancies

      new_files = get_files files
      results_texts = pyspelling_results(new_files)

      spell_issues = results_texts.select { |_, output| output.include? 'Spelling check failed' }

      # Get some metadata about the local setup
      current_slug = env.ci_source.repo_slug

      if spell_issues.count.positive?
        update_message_for_issues(spell_issues, current_slug)
      end
    end

    #
    # <Description>
    #
    # @param [<Hash>] spell_issues <description>
    # @param [<String>] current_slug <description>
    #
    # @return [Array<String>] <description>
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
          unless ignore_line(txt, path)
            File.foreach(path) { |path_line|
              if path_line.strip.include?(" #{txt.strip}")
                message << "#{$.} | #{txt} \n "
              end
            }
          end
        end
      end
      markdown message
    end

    #
    # TODO
    #
    # @param [<Type>] new_files <description>
    #
    # @return [<Type>] <description>
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
    # TODO
    #
    # @param [<Type>] current_slug <description>
    # @param [<Type>] path <description>
    #
    # @return [<Type>] <description>
    #
    def git_check(current_slug, path)
      if defined? @dangerfile.github
        return "/#{current_slug}/tree/#{github.branch_for_head}/#{path}"
      elsif defined? @dangerfile.gitlab
        return "/#{current_slug}/tree/#{gitlab.branch_for_head}/#{path}"
      else
        raise 'This plugin does not yet support bitbucket, would love PRs: https://github.com/hamstringassassin/danger-spelling/'
      end
    end

    #
    # TODO
    #
    # @return [<Type>] <description>
    #
    def check_for_dependancies
      raise 'pyspelling is not in the users PATH, or it failed to install.' unless pyspelling_installed?

      raise 'aspell or hunspell must be installed in order for pyspelling to work.' unless aspell_hunspell_installed?
    end

    #
    # TODO
    #
    # @param [<String>] text <description>
    # @param [<String>] file_path <description>
    #
    # @return [<Bool>] <description>
    #
    def ignore_line(text, file_path)
      text.strip == "Misspelled words:" ||
      text.strip == "<text> #{file_path}" ||
      text.strip == '!!!Spelling check failed!!!' ||
      text.strip == '--------------------------------------------------------------------------------' ||
      text.strip == ''
    end

    #
    # TODO
    #
    # @param [<Array>] spelling_errors <description>
    # @param [<String>] file_path <description>
    #
    # @return [<Array>] <description>
    #
    def remove_ignored_words(spelling_errors, file_path)
      spelling_errors.delete("Misspelled words:")
      spelling_errors.delete("<text> #{file_path}")
      spelling_errors.delete('!!!Spelling check failed!!!')
      spelling_errors.delete('')
      ignored_words.each do |word|
        spelling_errors.delete(word)
      end
      spelling_errors
    end

    #
    # TODO
    #
    # @return [<Type>] <description>
    #
    def pyspelling_installed?
      'which pyspelling'.strip.empty? == false
    end

    #
    # TODO
    #
    # @return [<Type>] <description>
    #
    def aspell_installed?
      'which aspell'.strip.empty? == false
    end

    #
    # TODO
    #
    # @return [<Type>] <description>
    #
    def hunspell_installed?
      'which hunspell'.strip.empty? == false
    end

    #
    # TODO
    #
    # @return [<Type>] <description>
    #
    def aspell_hunspell_installed?
      aspell_installed? && hunspell_installed?
    end

    #
    # TODO
    #
    # @param [<Danger::FileList>] files <description>
    #
    # @return [<Danger::FileList>] <description>
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
