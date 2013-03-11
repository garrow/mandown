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

require 'yaml'

# Define the text that is displayed when the user asks for documentation
def eqndown_documentation
<<END

  eqndown --- part of the Mandown set of tools.
  
  eqndown ...
  
  Copyright © 2008 Chris Rose. 
  Distributed according to the GNU General Public License.
  
  Usage:
  ------
  cat infile.txt | eqndown > outfile.txt
  
  Syntax:
  -------
  
  ...
  
  ------------------------------- Example -------------------------------------
  ...
  
  ------------------------------- End of example ------------------------------
  
  
  
  Notes:
  ------
  
  ...
  
  
  See also:
  ---------
  
  Markdown -- http://daringfireball.net/projects/markdown/
  Pandoc   -- http://johnmacfarlane.net/pandoc/
  
END
end


# Given a line of manuscript, return an array of the equations that it contains, if any.
def extract_eqn_text(line)
  i = 0
  eqn_text = ['']
  in_eqn = false
  line.each_byte do |x|
    x = x.chr
    if x == '$'
      in_eqn = !in_eqn
      if !in_eqn # Switching out of eqn mode.
        i = i+1 # Move onto the next item in the array of eqn texts.
        eqn_text[i] = '' # Can cause empty tail element.
      end
      next # Move onto the next character.
    end
    if in_eqn
      eqn_text[i]+=x
    end
  end
  eqn_text.delete_if {|x| x==''} # Remove empty elements.
end




def eqndown_main
  # Handle request for documentation.
  if ARGV.length > 0 && ARGV[0] == '--help'
    puts eqndown_documentation
    exit
  end
  
  # Read the file from standard input.
  lines = STDIN.readlines
  
  # Process the lines.
  manuscript = TODO
  
  # Send the processed manuscript to standard output.
  STDOUT.puts(manuscript)  
end