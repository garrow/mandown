#################### License ###################################################
# 
# Copyright (c) 2008 Chris Rose
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
################################################################################

# Define the text that is displayed when the user asks for documentation
def secdown_documentation
<<END


  secdown --- part of the Mandown set of tools.
  
  secdown processes standard input and:
    * automatically numbers sections;
    * allows you to reference other sections and automatically uses the correct 
      section number.
    
  Copyright © 2008 Chris Rose. 
  Distributed according to the GNU General Public License.
  
  Usage:
  ------
  cat infile.txt | secdown > outfile.txt
  
  Syntax:
  -------
  
  Standard Markdown provides two ways to indicate headings: the first style uses 
  '=' or '-' characters placed under the title (for first and second level 
  headings respectively); the second uses leading '#' characters, where the 
  number of '#' characters indicates the nesting level.
  
  ------------------------------- Example -------------------------------------

  This is a level 1 heading
  =========================
  
  This is a level 2 heading
  -------------------------
  
  # This is also a level 1 heading
  
  ## This is also a level 2 heading
  
  ## So is this
  
  ### This is a level 3 heading

  ### So is this

  ------------------------------- End of example ------------------------------

  secdown automatically numbers sections. For example, the above example 
  would be given the following section numbers (the actual result is not shown, 
  but this indicates the resulting numbering):
  
  1 This is a level 1 heading
    1.1 This is a level 2 heading
  2 This is also a level 1 heading
    2.1 This is also a level 2 heading
    2.2 So is this
      2.2.1 This is a level 3 heading
      2.2.2 So is this
  
  secdown outputs all headings in the '#'-based style, irrespective of the input 
  style.
  
  secdown does not insert a heading number for '# Bibliography', which is 
  reserved for use by the bibdown tool.
  
  secdown provides a way to reference other sections. To label a section (or 
  subsection, etc.), insert a line containing a label of the form 
  'label:some-label' somehwere in the section you want to reference. To 
  reference the section, place one of the following in-line with your text:
  
  * 'sec:some-label'  to generate something like   'section 3.2'
  * 'Sec:some-label'  to generate something like   'Section 3.2'
  * '§:some-label'    to generate something like   '§3.2'
  
  Section labels will be removed and will not be output by secdown.
    
  ------------------------------- Example -------------------------------------

  The following text

      # This is a heading  
      label:first-section
  
      This is a reference to the second section, sec:second-section.
  
      # This is another heading
      label:second-section
      
      This is a reference to the first section, sec:first-section.
  
  Would be turned into
  
      # 1 This is a heading
      
      This is a reference to the second section, section 2.
      
      # 2 This is another heading
      
      This is a reference to the first section, section 1.  
  
  ------------------------------- End of example ------------------------------

  You can use 'Sec:some-label' if you want the generated reference to use 
  'Section 3.2' rather than 'section 3.2' (i.e. the difference is the case of 
  the 's' in section), or '§:some-label' to generate '§3.2'.


  See also:
  ---------
  
  Markdown -- http://daringfireball.net/projects/markdown/
  Pandoc   -- http://johnmacfarlane.net/pandoc/
  
END
end


# Return true if the string contains an atx-style header and false otherwise.
def atx_header?(line)
  if /#+ \w*/.match(line).nil?
    false
  else
    true
  end
end

# Given an atx-style header string of the form '# Something ...' or '##
# Something ...', return an integer that indicates the nesting level; '#'
# would be level 1, '##' would be level 2, etc. Returns 0 if the text is not
# an atx-style header.
def get_atx_nesting_level(atx_header)
  # Check that we have an atx header.
  return 0 if !atx_header?(atx_header)
  atx_header.split[0].length # Return the number of leading # characters.
end

# Given a string, return true if all the characters are equal to char, or
# false otherwise. Note that if the line ends with a newline, this will be
# ignored.
def all_chars?(line, char)
  return false if line.nil?
  line = line.strip
  chars_array = line.split('').uniq
  return true if chars_array.length == 1 && chars_array[0] == char
  return false
end

# Given an array of strings, where the (i+1)-th string is the line that
# appears after the i-th line, convert setx-style headings (those that use
# underlining to indicate nesting level) to atx style (where a given number of
# # character are used). Return the resulting array of lines.
def setx_to_atx(lines)
  ret_val = []
  lines.each_index do |i|
    # Get the next two lines, if there are, else quit looking.
    if lines.length > i-2
      this_line = lines[i]
      next_line = lines[i+1]

      if all_chars?(next_line, '=')
        ret_val.push('# ' + this_line)
      elsif all_chars?(next_line, '-')
        ret_val.push('## ' + this_line)
      elsif all_chars?(this_line, '-') || all_chars?(this_line, '=')
        # Do nothing, but keep this condition in!
      else
        ret_val.push(this_line)
      end
    end
  end
  ret_val
end

# Given the nesting level of a header (e.g. 2, as returned by
# get_atx_nesting_level) and a string which specifies the previous heading
# nesting level (e.g. '1.2.1'), return the heading nesting level string for
# the header (e.g. '1.3', in this example).
def get_heading_level_string(current_nesting, previous_level)
  if previous_level.split('.').length < current_nesting
    # The case where we need to move to a deeper nesting level.
    previous_level + '.1'
  else
    # The case where we need to remain at the current, or move up, a level.
    t = previous_level.split('.')
    t = t[0..current_nesting-1]
    t[-1] = (t[-1].to_i + 1).to_s
    t.join('.')
  end
end

# Given a string that specifies the previous heading nesting level string
# (e.g. '1.3.1') and an atx-style header (e.g. '## Header'), return  the next
# heading nesting level string (e.g. '## 1.4', in this example) and return it.
def get_next_level_string(previous, header)
  # Get the level and the string to insert.
  if previous == ''
    '1'
  else
    get_heading_level_string(get_atx_nesting_level(header), previous)
  end
end


# Given a string that specifies the level of a heading (e.g. '1.2.3' such as
# returned by get_next_level_string, for example), and an atx-style header
# string, insert the level string into the header and return it.
def insert_level_to_atx_header(level_string, header)
  level = get_atx_nesting_level(header)
  header[0..level-1] + ' ' + level_string + header[level..-1]  
end


# Given an array of lines of text, insert appropriate leading section numbers,
# and return the resulting array. By default, ignore the bibliography line.
def insert_header_levels(lines, ignore_bibliography = true)
  lines = setx_to_atx(lines) # Convert setx-style headers to atx-style.
  
  current_level_string = '0'
  ret_val = []
  lines.each do |line|
    if atx_header?(line) && /# Bibliography/.match(line) && ignore_bibliography
      ret_val.push(line)
    elsif atx_header?(line)
      current_level_string = get_next_level_string(current_level_string, line)
      ret_val.push(
        insert_level_to_atx_header(current_level_string, line))
    else
      ret_val.push(line)
    end
  end
  ret_val
end

# Take a header string that contains a leading section number and return that
# number.
def get_section_number_from_header(header)
  tmp = header.scan(/(\d+((\.\d)+))/)
  if tmp.empty?
    header.scan(/(\d+)/)[0][0]
  else
    tmp[0][0]
  end
end


# Take a manuscript, as an array of lines, that has been processed by
# insert_header_levels, and replace isnstances of 'sec:some-label' with the
# section number that the the label was defined in using 'label:some-label'.
# Remove lines that contain the label definition and return the result.
def replace_section_references(lines)
  # First parse the lines to get a mapping between the label names and the
  # section numbers they appear in.
  current_section_number = nil
  label_section_map = {} # Will map labels to section numbers.
  ret_val = []
  lines.each do |line|
    # Get the label:some-label string, if it is on this line, as an array.
    label_string_arr = line.scan(/^label:\w+[-_\.]*\w*/)
    
    if atx_header?(line)
      current_section_number = get_section_number_from_header(line)
    elsif !label_string_arr.empty?
      label = label_string_arr[0].split('label:')[1] # Get the label.
      label_section_map[label] = current_section_number
      line = nil # Kill off the label.
    else
      # Do nothing.
    end
    ret_val.push(line) unless line.nil?
  end

  # Now process ret_val to replace instances of 'sec:some-label' with 'section
  # 3.2' or whatever.
  ret_val.each_index do |i|
    label_section_map.each_pair do |key, value|
      from_to = {"sec:#{key}" => "section #{value}",
        "Sec:#{key}" => "Section #{value}",
        "§:#{key}" => "§#{value}"}
      from_to.each_pair do |f, t|
        ret_val[i].gsub!(f, t)
      end
    end
  end
  ret_val
end



# Read the manuscript from standard input and insert appropriately nested level numbering (e.g. '2.1') and send the result to standard output.
def secdown_main
  # Handle request for documentation.
  if ARGV.length > 0 && ARGV[0] == '--help'
    puts secdown_documentation
    exit
  end
  
  # Read the file from standard input.
  lines = STDIN.readlines
  
  # Insert the level numbers.
  manuscript = insert_header_levels(lines)
  
  # Send the processed manuscript to standard output.
  STDOUT.puts(manuscript)
end