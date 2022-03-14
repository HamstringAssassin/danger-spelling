
require "spelling/plugin"
require 'json'

module Danger
  
  class DangerSpelling < Plugin

    attr_accessor :ignored_words

    attr_accessor :ignored_files

    def check_spelling(files = nil)
      puts "--------BEGIN----------"
      system 'pip install --user pyspelling' unless pyspelling_installed?
      
      raise "pyspelling is not in the users PATH, or it failed to install" unless pyspelling_installed?
      
      if !aspell_installed?
        raise "aspell or hunspell must be installed in order for pyspelling to work correctly"
      end
      
      new_files = get_files files
      # puts new_files
      results_texts = {}
      # puts "finished getting files"
      new_files.each do |file|
        file_result = `pyspelling --name 'source' --source '#{file}'`
        # puts "file result ----"
        # puts file_result
        results_texts[file] = file_result
      end

      spell_issues = results_texts.select { |path, output| output.include? "Spelling check failed" }

      # File.write(".spelling", skip_words.join("\n"))
      # result_texts = Hash[files.to_a.uniq.collect { |file| 
      #   puts file
      #   [file, `pyspelling --source #{file}`.strip] }]
      # puts result_texts
      # spell_issues = result_texts.select { |path, output| output.include? "spelling errors found" }
      
      # puts "Spell issues ===="
      # puts spell_issues
      # File.unlink(".spelling")
      
      # Get some metadata about the local setup
      current_slug = env.ci_source.repo_slug
      # puts current_slug
      
      if spell_issues.count > 0
        message = "### Spell Checker found issues\n\n"
        spell_issues.each do |path, output|
          if defined? @dangerfile.github
            git_loc = "/#{current_slug}/tree/#{github.branch_for_head}/#{path}"
          elsif defined? @dangerfile.gitlab
            git_loc = "/#{current_slug}/tree/#{gitlab.branch_for_head}/#{path}"
          else
            raise "This plugin does not yet support bitbucket, would love PRs: https://github.com/dbgrandi/danger-prose/"
          end
          
          message << "#### [#{path}](#{git_loc})\n\n"
          
          message << "Line | Typo |\n "
          message << "| --- | ------ |\n "

          output_array = output.split(/\n/)

          output_array = remove_ignored_words(output_array, path)

          if path.include?("data.yml")
            puts "include data.yml in output"
          end
          output_array.each do |txt|
            if path.include?("data.yml")
              puts "spelling mistake from data.yml"
              puts txt
            end
            # puts ignore_line(txt)
            unless ignore_line(txt, path)
              File.foreach(path) { |path_line|
                if path.include?("data.yml")
                  puts "line and mistake from data.yml"
                  puts path_line
                  puts txt
                end
                # puts path_line.strip.include?(txt.strip)
                if path_line.strip.include?(" #{txt.strip} ")
                  message << "#{$.} | #{txt} \n "
                  # puts "message===="
                  # puts message
                end
              }
            end
          end
          markdown message
        end
      end
      
      puts "--------END----------"
    end

    def skip_words
      [""]
    end
    
    def ignore_line(text, file_path)
      # file_path = '_data/data.yml'
      text.strip == "Misspelled words:" ||
      text.strip == "<text> #{file_path}" ||
      text.strip == '!!!Spelling check failed!!!' ||
      text.strip == '--------------------------------------------------------------------------------' ||
      text.strip == ''
    end

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
    
    def pyspelling_installed?
      'which pyspelling'.strip.empty? == false
    end
    
    def aspell_installed? 
      'which aspell'.strip.empty? == false
    end
    
    def hunspell_installed?
      'which hunspell'.strip.empty? == false
    end
    
    def get_files files
      # puts (git.modified_files + git.added_files)
      # Either use files provided, or use the modified + added
      found_files = files ? Dir.glob(files) : (git.modified_files + git.added_files)
      ignored_files.each do |file|
        found_files.delete(file)
      end
      found_files
    end
    
    # Always returns a hash, regardless of whether the command gives JSON, weird data, or no response
    def get_pyspelling_json path
      output = `pyspelling --source "#{path}"`.strip
    end
  end
end
