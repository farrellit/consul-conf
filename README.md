
# Config Options

<dl>
<h4>Required</h4>
<dt>template</dt> <dd>the ERB template to use to generate new configurations</dd>
<dt>outfile</dt> <dd>the destination - the config file to rewrite</dd>
<dt></dt> <dd></dd>
<h4>Optional</h4>
<dt>comment_regex</dt> <dd>A regular expression ( passed to `Regexp.new`) to pull comments out of the template ( so that comments are not included in the diff when checking for updates).  You might consider using `"^\\s*#"` for files with hashed comment lines.  <br/><em>Note:</em> be sure to escape backslashes!</em></dd>
<dt>postupdate</dt> <dd>A command to run after updating the config file ( eg restarting a service )</dd>
<dt>postupdate_status</dt> <dd>An 8-bit integer status code to expect from the postupdate command, only considered if the `postupdate` option is specified.  </dd>
</dl>
