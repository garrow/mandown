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
def bibdown_documentation
<<END


  bibdown --- part of the Mandown set of tools.
  
  bibdown processes standard input, builds a bibliography from a YAML-format set 
  of references and inserts citation keys.
  
  Copyright © 2008 Chris Rose. 
  Distributed according to the GNU General Public License.
  
  Usage:
  ------
  cat infile.txt | bibdown > outfile.txt
  
  Syntax:
  -------
  
  Place references at the end of your Markdown file in a level 1 section 
  called 'Bibliography' using the exact string '# Bibliography' (as given in the 
  example below). Cite references in your text using 'cite:MyKey', where 'MyKey' 
  is a key to one of your references. Keys may contain any characters, but end 
  with a space character (i.e. 'cite:SomeKey' refers to the key 'SomeKey', while 
  'cite:Some Key' refers to the key 'Some').
  
  ------------------------------- Example -------------------------------------
  ...
  This is some text that needs to cite the very important work of Jones and 
  Smith cite:Jones.
  ...
  
  # Bibliogrqaphy
  
  Jones:
    authors:  Jones, Bob & Smith, Fred J.
    title:    Spaghetti-Wall Interactions
    journal:  Am. J. Pasta Phys.
    volume:   3
    number:   2
    month:    January
    year:     2008
    pages:    111--112
    note:     In press.
  ------------------------------- End of example ------------------------------
  
  Suppoted fields:
  ----------------
  
  The following fields are supported by bibdown and all are optional; you may 
  use other arbitrarily-named fields, but they will be ignored (by this version 
  of bibdown, at least).
  
  authors -- Use 'surname, first names' format; separate authors with '&'.
      e.g. "Einstein, Albert & Bohr, Neils"
  organization -- Use if the publication is authored by an organization.
      e.g. "Amnesty International"
  title -- The title of the reference.
      e.g. "Some Clever Stuff on Quantum Physics"
  journal -- The name of the journal; this field causes the reference to be 
             treated as an article in a journal.
      e.g. "Int. J. Quan. Phys."
  conference -- The name of the conference; this field causes the reference to 
                be treated as a paper in a conference proceedings.
      e.g. "Medical Image Understanding and Analysis"
  booktitle -- The title of a book; this field causes the reference to be 
               treated as a book.
      e.g. "Moby Dick"
  chapter -- The chapter in a book being cited; only valid for references 
             that use the booktitle field.
      e.g. "4"
  edition -- The edition of a book being cited; only valid for references 
             that use the booktitle field.
      e.g. "5"
  editors -- The editors of a book being cited; only valid for references 
             that use the booktitle field.
      e.g. "Harris, Thomas & Hopper, Dennis"
  isbn -- The ISBN number of a book being cited; only valid for references 
          that use the booktitle field. 
      e.g. "9783540356257"
  month -- The month of publication.
      e.g. "January"
  volume -- The volume of the publication being cited.
      e.g. "2"
  number -- The number/issue of the journal article being cited; only valid for 
            references that use the journal field.
      e.g. "2"
  pages -- The pages in the publication being referred to.
      e.g. "201--211"
  series -- The series the book being cited belongs to; only valid for 
            references that use the booktitle field.
      e.g. "Mathematical Statistics"
  url -- A URL for the publication being cited.
      e.g. "http://www.something.com/somedocument"
  accessed -- The date the URL was accessed (note: do not use this field without 
              also including a URL).
      e.g. "28 January 2008"
  year -- The year the publication being cited was published.
      e.g. 2008
  note -- Any notable comment about the publication being cited.
      e.g. "In press."
  
  
  Notes:
  ------
  
  You must use soft tabs (emulated using spaces) in the bibliography. If you 
  need to include a colon in the reference (e.g. in the title field), you 
  will need to surround the field entry in quotes (e.g. "title:  'Gnocci: nasty 
  or nice?'").
  
  If you are going to process the resulting file (outfile.txt, in the usage 
  example given above), you may wish to use a double-dash for page ranges 
  (and be sure to use the 'smart typography' mode of Pandoc)---see the example 
  above.
  
  See also:
  ---------
  
  Markdown -- http://daringfireball.net/projects/markdown/
  Pandoc   -- http://johnmacfarlane.net/pandoc/
  
END
end


# Given a symbol identifying a part of a citation (e.g. :journal), return the
# separator string that should follow it (e.g. a '. ' follows the name of the
# journal). (Note: include any following space!)
def get_sep(part)
  sep = case part
    when :authors, :organization, :title, :booktitle, :isbn, :series, :accessed, :year
      '. '
    when :journal, :conference, :chapter, :edition, :pages, :url
      ', '
    when :editors
      ', editors. '
    when :month, :note
      ' '
    when :number, :volume
      ''
  end
  
  sep
end

# Define a function that takes a string and returns that string marked as being of :normal (upright) or :italic using Markdown notation.
def markdown_format(string, style)
  case style
    when :normal: string
    when :italic: '*' + string + '*'
  end
end

# Define a function to render a string as normal using Markdown notation.
def r_norm(string)
  markdown_format(string, :normal)
end

# Define a function to render a string as italic using Markdown notation.
def r_ital(string)
  markdown_format(string, :italic)
end


# Given a bib entry (a hash that maps the parts of a reference to the content
# for that reference), construct a string that can be used in a paper as the
# bibliographic entry for that entry. Also return information that can be used
# to sort the bibliography (first author surname, publication year). Also
# return the key that was used in the text to refer to this citation. Return a
# hash with fields :reference (containing the reference), :sort_info and :key.
# :sort_info is a hash with fields :surname and :year.
#
# See the documentation string above for details on what fields are supported
# and how they should behave.
def make_bib_entry_string(bib_entry, key)
  # We'll encode the order in which the parts of the reference appear for the
  # three types of reference in three arrays; we'll associate these arrays
  # with symbols that specify the reference type.
  order = {
    :journal =>
      [:authors, :organization, :title, :journal, :volume, :number, :pages,
        :month, :year, :url, :accessed, :note],
    :conference =>
      [:authors, :organization, :title, :conference, :editors, :volume, :pages,
        :month, :year, :isbn, :url, :accessed, :note],
    :book =>
      [:authors, :organization, :editors, :booktitle, :series, :edition,
        :volume, :chapter,  :pages, :month, :year, :isbn, :url, :accessed,
        :note]}
  
  # Cope with the misc type.
  order[:misc] = order[:journal]

  # Use an associative array to specify how each part of a citation should be
  # styled. We map from the parts to functions which perform the required
  # styling.
  styles = {:authors => proc {|x| r_norm(x)},
   :organization => proc {|x| r_norm(x)}, :title => proc {|x| r_norm(x)},
   :journal => proc {|x| r_ital(x)}, :conference => proc {|x| r_ital(x)},
   :booktitle => proc {|x| r_ital(x)}, :chapter => proc {|x| r_norm(x)},
   :edition => proc {|x| r_norm(x)}, :editors => proc {|x| r_norm(x)},
   :isbn => proc {|x| r_norm(x)}, :month => proc {|x| r_norm(x)},
   :note => proc {|x| r_norm(x)}, :number => proc {|x| r_norm(x)},
   :pages => proc {|x| r_norm(x)}, :series => proc {|x| r_norm(x)},
   :url => proc {|x| r_norm(x)}, :accessed => proc {|x| r_norm(x)},
   :volume => proc {|x| r_norm(x)}, :year => proc {|x| r_norm(x)}}
   
  # Make a copy for later, as we alter the original bib_entry object.
  org_bib_entry = bib_entry.clone
      
  # Make the author string and replace the entry in the bib_entry with the
  # formatted version. Do similarly with the editors.
  bib_entry['authors'] = 
    make_author_string(bib_entry['authors']) if !bib_entry['authors'].nil?
  bib_entry['editors'] = 
    make_author_string(bib_entry['editors']) if !bib_entry['editors'].nil?
  
  # See if we're making a journal article, conference paper or book reference.
  ref_type = :journal unless bib_entry['journal'].nil?
  ref_type = :conference unless bib_entry['conference'].nil?
  ref_type = :book unless bib_entry['booktitle'].nil?
  if !(defined? ref_type) || ref_type.nil?
    ref_type = :misc
    STDERR.puts('Note: Reference type not found for reference ' + key)
  end
  
  # Get the order for the type of entry we're dealing with.
  order = order[ref_type]
  
  # Iterate over the parts of the citation for this type of reference and
  # build the bibliography entry.
  bib_entry_string = ''
  order.each do |part_name|
    # Construct the part of the entry for the given part_name, taking into
    # account the fact that some parts need to be formatted in certain ways.
    if bib_entry[part_name.to_s] # If there is an entry for this part name...
      part = bib_entry[part_name.to_s].to_s
    else
      part = ''
    end
    
    # Format the part of the reference using the appropriate style.
    part = styles[part_name].call(part)
    
    part = case part_name
      when :authors, :organization, :booktitle, :isbn, :series, :year
        part + '. '
      when :title
        # Only add an '.' if doesn't already end with a punctuation character.
        if /[[:punct:]]$/.match(part): part + ' '
        else part + '. '
        end
      when :conference
        'In proc. ' + part + ', '
      when :journal, :conference, :chapter, :edition
        part + ', '
      when :editors
        part + ', editors. '
      when :month
        part + ' '
      when :volume
        part
      when :number, :note
        '(' + part + ')'
      when :pages
        if ref_type == :journal
           ':' + part + ', '
        elsif ref_type == :conference || ref_type == :book
           'pp' + part + ', '
        end
      when :url
        'Available at: ' + part
      when :accessed
        ', accessed ' + part + '. '
      else
        part
    end
    
    bib_entry_string += part if bib_entry[part_name.to_s]
  end
  
  # Make sure the bib_entry_string ends with a punctuation character,
  # appending a full stop if it doesn't.
  bib_entry_string.strip!
  bib_entry_string += '.' unless /[[:punct:]]$/.match(bib_entry_string)
  
  # Get the surname for sorting purposes. Use the author as first preference
  # if it is available, otherwise use the organisation, otherwise use a sort
  # surname that will place it last.
  sort_surname = 'ZZZ' # The default if we can't find something better.
  sort_surname = 
    org_bib_entry[:organization] if !bib_entry['organization'].nil?
  sort_surname = 
    get_first_author_surname(org_bib_entry) if !bib_entry['author'].nil?
  
  
  # Make the hash to return.
  { :reference => bib_entry_string,
    :key => key,
    :sort_info => {:surname => sort_surname, :year => bib_entry['year']}}
end

# Return the surname of the first author in lowercase.
def get_first_author_surname(bib_entry)
  make_author_string(
    bib_entry['authors'], true, true).split[0][0..-2].downcase
end


# Given a string of the form 'Chris James' turn it into a string of the form 'C. J.'
def make_initials(firstnames)
  firstnames = firstnames.split(' ')
  firstnames.each_index do |i|
    firstnames[i] = firstnames[i][0].chr + '.'
  end
end

# Given a string of the form 'Rose, Chris & Jones, Bob', make an authors
# string that can be placed in the bibliography.
#
# use_initials specifies whether the full firstnames are used, or whether
# initials are used instead.
#
# surname_first specifies whether the author surnames should appear before
# their first names or initials.
def make_author_string(authors, use_initials=true, surname_first=false)
  # Strip out the individual authors and remove leading and trailing
  # whitespace, and split each into surname and firstnames.
  authors = authors.split('&')
  authors.each_index do |i|
    authors[i].strip!
    authors[i] = authors[i].split(',')
    authors[i][0].strip!
    authors[i][1].strip!
  end
  
  # If we have to use first initials for the first names, then make them.
  if use_initials
    authors.each_index do |i|
      authors[i][1] = make_initials(authors[i][1])
    end
  end

  # Now make the authors string.
  authors_string = ''
  authors.each_index do |i|
    # Get a string for the forename(s) for the i-th author.
    this_forenames = ''
    authors[i][1].each do |name_or_initial|
      this_forenames += name_or_initial + ' '
    end

    # Concatenate the forename(s) and surname in the appropriate order.
    if surname_first
      authors_string += authors[i][0] + ', '
      authors_string += this_forenames.rstrip
    else
      authors_string += this_forenames
      authors_string += authors[i][0] 
    end
    authors_string += ', ' unless i == authors.length-1 or i == authors.length-2
    authors_string += ' and ' if i == authors.length-2
  end
  
  authors_string.strip! # Remove leading and trailing whitespace.
  authors_string # Return the authors string.
end


# Given an array of bib_entries, each made using the make_bib_entry_string
# function, sort this array according to first author surname, or year of
# publication, or by the order in which the papers were cited in the text.
#
# keys_in_order must be an array containing the keys used in the text, in the
# order the keys appear in the text, without repetition. by must be one of
# :surname, :year or :order_in_text
def sort_bib_entries(bib_entries, keys_in_order, by = :surname)
  case by
  when :surname, :year
    bib_entries.sort {|x,y| x[:sort_info][by] <=> y[:sort_info][by]}
  when :order_in_text
    to_return = []
    keys_in_order.each do |key|
      bib_entries.each do |entry|
        to_return.push(entry) if entry[:key] == key
      end
    end
    to_return
  end
end


# Given a string containing the YAML for the bibliography, and an array
# containing the keys in the order they appear in the text (without
# repetitions), make an array of strings where each string is a bibliographic
# entry (i.e. can be placed directly in the bibliography). The entries
# returned will be sorted in an appropriate order.
def make_bib_entries(bibliography_yaml, keys_in_order)
  # Convert the YAML text to a Ruby data type.
  objs = YAML.load(bibliography_yaml)

  # Make each bibliography entry string (the references).
  bib_entries = Array.new
  objs.each_key do |key|
    bib_entries.push(make_bib_entry_string(objs[key], key))
  end
  
  # Sort the references & return.
  sort_bib_entries(bib_entries, keys_in_order, :order_in_text)
end

# Define a function that returns true if bib_entries contains an entry for a
# given citation key.
def has_key?(key, bib_entries)
  ret_val = false
  bib_entries.each do |entry|
    ret_val = true if entry[:key] == key
  end
  ret_val
end

# Get an array that contains the reference keys in the order they are cited,
# without repetitions.
def get_keys_in_order(plaintext)
  all_keys = plaintext.scan(/cite:\w*/)
  all_keys.uniq! # Remove duplicates.
  uniq_keys = []
  all_keys.each {|x| uniq_keys.push(x.split('cite:')[1])} # Remove the 'cite:'  
  uniq_keys
end

# Convert bib_entries into a string that can be placed at the end of the
# plaintext as the bibliography. The parenthesis style using the 
# citation_parens argument.
def render_bibliography(bib_entries, citation_parens)
  ret_val = "\n"
  bib_entries.each_index do |i|
    ret_val += # The reference number.
      citation_parens[0].chr + (i+1).to_s + citation_parens[1].chr
    ret_val += ' ' + bib_entries[i][:reference] # The reference.
    ret_val += "  \n" # __\n is Markdown for a linebreak.
  end
  
  ret_val
end

# Given the plaintext containing the key-based citations, and the bib_entries,
# make the final manuscript by replacing the key-based citations (in the text)
# with human-readable citations and place the bibliography at the end. Specify
# the parenthesis style using the optional citation_parens argument.
def make_manuscript(plaintext, bib_entries, citation_parens='[]')
  bib_entries.each_index do |i|
    plaintext.gsub!("cite:#{bib_entries[i][:key]}",
      citation_parens[0].chr + "#{i+1}" + citation_parens[1].chr)
  end
  
  plaintext + render_bibliography(bib_entries, citation_parens)
end

# Check the final manuscript for instances of cite:SomeKey (for example), and
# return an array of messages identifying the keys that were not defined in
# the bibliography.
def check_missing_citations(manuscript)
  ret_val = []
  # Get the remaining keys.
  remaining_keys = get_keys_in_order(manuscript)
  remaining_keys.each do |key|
    ret_val.push('The following reference key was undefined: ' + key)
  end
  
  ret_val
end

# Read the text containing the citations from standard input, process the
# references and send the result to standard output, reporting errors to
# standard error. This program is written to allow it to be chained with other
# manuscript-processing tools in a UNIX pipeline. To read/write from/to files,
# do:
#
# cat my-paper.txt | ruby make_paper.rb > my-paper-with-bib.txt
def bibdown_main
  # Handle request for documentation.
  if ARGV.length > 0 && ARGV[0] == '--help'
    puts bobdown_documentation
    exit
  end
  
  # Read the .txt file from standard input and get the plain text and the
  # bibliography
  parts = STDIN.readlines('# Bibliography')
  plaintext = parts[0]
  bibliography_yaml = parts[1]
  
  # Get an array that contains the reference keys in the order they are cited,
  # without repetitions.
  keys_in_order = get_keys_in_order(plaintext)
  
  # Make a list of bibliography enties, sorted in the correct order.
  bib_entries = make_bib_entries(bibliography_yaml, keys_in_order)
  
  # Now make the final manuscript by replacing the key-based citations (in the
  # text) with human-readable citations and place the bibliography at the end.
  manuscript = make_manuscript(plaintext, bib_entries)
  
  # Send the manuscript to standard output.
  STDOUT.puts(manuscript)
  
  # Now perform some checks for possible user errors and report then on
  # standard error.
  user_errors = []
  user_errors.concat(check_missing_citations(manuscript))
  user_errors.each {|x| STDERR.puts(x)} # Report the user errors.
  
end