# frozen_string_literal: true

require File.expand_path('spec_helper', __dir__)

module Danger
  describe Danger::DangerSpelling do
    it 'should be a plugin' do
      expect(Danger::DangerSpelling.new(nil)).to be_a Danger::Plugin
    end

    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @spelling = @dangerfile.spelling

        # mock the PR data
        # you can then use this, eg. github.pr_author, later in the spec
        # json = File.read("#{File.dirname(__FILE__)}/support/fixtures/github_pr.json") 
        # example json: `curl https://api.github.com/repos/danger/danger-plugin-template/pulls/18 > github_pr.json`
        # https://api.github.com/repos/HamstringAssassin/resume/pull/2
        # allow(@my_plugin.github).to receive(:pr_json).and_return(json)
      end

      describe 'pre-install checks and dependencies' do
        # it 'handles not having pyspelling set' do
        #   allow(@spelling).to receive(:`).with('which pyspelling').and_return('')
        #   expect(@spelling.pyspelling_installed?).to be_falsy
        # end

        # it 'handles name not being set' do
        #   expect(@spelling.name).to eq('')
        # end

        it 'handles name being set' do
          @spelling.name = 'test_name'
          expect(@spelling.name).to eq('test_name')
        end

        it 'handles pyspelling not being installed' do
          allow(@spelling).to receive(:pyspelling_installed?).and_return(false)
          expect { @spelling.check_for_dependancies }.to raise_error('pyspelling is not in the users PATH, or it failed to install.')
        end

        it 'handles pyspelling being installed' do
          allow(@spelling).to receive(:aspell_hunspell_installed?).and_return(false)
          expect { @spelling.check_for_dependancies }.to raise_error('aspell or hunspell must be installed in order for pyspelling to work.')
        end

        it 'handles name being an empty string' do
          @spelling.name = ""
          expect { @spelling.check_spelling }.to raise_error('name must be a valid matrix name in your .pyspelling.yml.')
        end

        it 'handles name being nil' do
          @spelling.name = nil
          expect { @spelling.check_spelling }.to raise_error('name must be a valid matrix name in your .pyspelling.yml.')
        end
      end

      describe 'pyspelling results ignore certain lines' do
        before do
          @dangerfile = testing_dangerfile
          @spelling = @dangerfile.spelling
        end

        it "should ignore 'Misspelled words:' from results" do
          initial = 'Misspelled words:    '
          file_path = 'test'
          expect(@spelling.ignore_line(initial, file_path)).to eq(true)
        end

        it "should remove '!!!Spelling check failed!!!' from results" do
          initial = '!!!Spelling check failed!!!    '
          file_path = 'test'
          expect(@spelling.ignore_line(initial, file_path)).to eq(true)
        end

        it "should remove '--------------------------------------------------------------------------------' from results" do
          initial = '--------------------------------------------------------------------------------    '
          file_path = 'test'
          expect(@spelling.ignore_line(initial, file_path)).to eq(true)
        end

        it 'should remove a given file_path from results' do
          initial = ' <text> test  '
          file_path = 'test'
          expect(@spelling.ignore_line(initial, file_path)).to eq(true)
        end
      end

      describe 'pyspelling results have certain words removed' do
        before do
          @dangerfile = testing_dangerfile
          @spelling = @dangerfile.spelling
        end

        it "should remove 'Misspelled words:' from results" do
          initial = ['string', 'Misspelled words:', 'string']
          expected = %w[string string]
          file_path = 'test'
          @spelling.ignored_words = []
          expect(@spelling.remove_ignored_words(initial, file_path)).to eq(expected)
        end

        it 'should remove the file path from results' do
          initial = ['string', '<text> test', 'string']
          expected = %w[string string]
          file_path = 'test'
          @spelling.ignored_words = []
          expect(@spelling.remove_ignored_words(initial, file_path)).to eq(expected)
        end

        it "should remove '!!!Spelling check failed!!!' from results" do
          initial = ['string', '!!!Spelling check failed!!!', 'string']
          expected = %w[string string]
          file_path = 'test'
          @spelling.ignored_words = []
          expect(@spelling.remove_ignored_words(initial, file_path)).to eq(expected)
        end

        it 'it should remove any user defined words from results' do
          initial = %w[string hammyassassin string]
          expected = %w[string string]
          file_path = 'test'
          @spelling.ignored_words = ['hammyassassin']
          expect(@spelling.remove_ignored_words(initial, file_path)).to eq(expected)
        end
      end

      describe 'when spelling errors are found' do
        before do
          @dangerfile = testing_dangerfile
          @spelling = @dangerfile.spelling
          @spell_issues = eval(File.read("#{File.dirname(__FILE__)}/fixtures/spell_issues.txt"))

          @json = File.read("#{File.dirname(__FILE__)}/fixtures/github_pr.json")
          allow(@spelling.github).to receive(:pr_json).and_return(@json)
        end

        it 'should generate the correct message for the github' do
          @spelling.ignored_words = []
          expected = ["### Spell Checker found issues\n\n#### [spec/fixtures/test.yml](/HamstringAssassin/resume/"\
          "tree//spec/fixtures/test.yml)\n\nLine | Typo |\n | --- | ------ |\n 1 | APIs \n 2 | Acitons \n "]
          expect(@spelling.update_message_for_issues(@spell_issues, 'HamstringAssassin/resume')).to eq(expected)
        end
      end

      describe 'when detecting a word in a given sentence' do
        it 'should ignore a spelling mistake if its part of a full word' do
          expect(@spelling.find_word_in_text('email is al@test.io', 'io')).to be_falsy
        end

        it 'should detect a word when its on its own and not part of another word' do
          expect(@spelling.find_word_in_text('email is al@test.io io', 'io')).to be_truthy
        end

        it 'should detect a word even at the end of a sentence' do
          expect(@spelling.find_word_in_text('email is al@test.io io.', 'io')).to be_truthy
        end
      end

      describe 'when checking for URLs' do
        it 'should detect a URL' do
          expect(@spelling.url?('https://www.google.com')).to be_truthy
        end

        it 'should detect a URL' do
          expect(@spelling.url?('https://google.com')).to be_truthy
        end

        it 'should detect a URL' do
          expect(@spelling.url?('http://google.com')).to be_truthy
        end

        it 'should detect a URL' do
          expect(@spelling.url?('https://google.com/test')).to be_truthy
        end

        it 'should detect a URL' do
          expect(@spelling.url?('https://google.com/test?test=2')).to be_truthy
        end

        it 'should not detect a URL' do
          expect(@spelling.url?('test@test.com')).to be_falsy
        end
      end
    end
  end
end
