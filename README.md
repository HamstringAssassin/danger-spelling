

### spelling

This is a Danger plugin that wraps the python library pyspelling and some of its usage.
The pyspelling results are posted to the pull request as a comment with the spelling mistake, file path &
line number where the spelling mistake was found.

It has some dependencies that should be installed prior to running.

* [pyspelling](https://facelessuser.github.io/pyspelling/)
* [aspell](http://aspell.net)
* **OR**
* [hunspell](http://hunspell.github.io)

Your repository will also require a .pyspelling.yml file to be present. This .pyspelling.yml can be basic,
but it will require a name and source property.

There are several ways to use this danger plugin

added in the given pull request.
         spelling.name = "test_matrix"
         spelling.check_spelling

request, excluding some specific file names
         spelling.ignored_files = ["Gemfile"]
         spelling.name = "test_matrix"
         spelling.check_spelling

request, excluding some specific file names and excluding some words
         spelling.ignored_words = ["HammyAssassin"]
         spelling.ignored_files = ["Gemfile"]
         spelling.name = "test_matrix"
         spelling.check_spelling

<blockquote>execute pyspelling matrix with the name 'test_matrix' on all files modified or
  <pre></pre>
</blockquote>

<blockquote>execute pyspelling matrix with the name 'test_matrix' on all files modified or added in the given pull
  <pre></pre>
</blockquote>

<blockquote>execute pyspelling matrix with the name 'test_matrix' on all files modified or added in the given pull
  <pre></pre>
</blockquote>



#### Attributes

`ignored_words` - Allows you to ignore certain words that might otherwise be detected as a spelling error.
default value is [] when its nil

`ignored_files` - Allows you to ignore certain files that might otherwise be scanned by pyspelling.
The default value is [] for when its nil

`name` - **required** The name of the test matrix in your .pyspelling.yml
An exception will be raised if this is not specified in your Danger file.




#### Methods

`check_spelling` - Checks the spelling of all files added or modified in a given pull request. This will fail if
pyspelling cannot be installed if not installed already. It will fail if `aspell` or `hunspell`
are not detected.

It will also fail if the required parameter `name` hasn't been specificed in the Danger file.


modified files will be scanned.

`update_message_for_issues` - **Internal Method**

Updates the message that will eventually be posted as a comment a pull request with
a new line for each time the spelling error has been detected.

`pyspelling_results` - **Internal Method**

Runs pyspelling on the test matrix name provided with any files given.

`git_check` - **Internal Method**

Check on the git service used. Will raise an error if using bitbucket as it currently doesnt support that.

`check_for_dependancies` - **Internal Method**

Check for dependencies. Raises exception if pyspelling, hunspell or aspell are not installed.

`ignore_line` - **Internal Method**

Checks if a given line can be ignored if it contains expected pyspelling output.

`remove_ignored_words` - **Internal Method**

Removes some standard words in the pyspelling results.
Words provided in `ignored_words` will also be removed from the results array.

`pyspelling_installed?` - **Internal Method**

Checks of pyspelling is installed.

`aspell_installed?` - **Internal Method**

Checks if aspell is installed.

`hunspell_installed?` - **Internal Method**

Checks if Hunspell is installed.

`aspell_hunspell_installed?` - **Internal Method**

checks if aspell and hunspell are installed.

`get_files` - **Internal Method**

Gets a file list of the files provided or finds modified and added files to scan.
If files are provided via `ignored_files` they will be removed from the final returned
list.

Will raise an exception if no files are found.




