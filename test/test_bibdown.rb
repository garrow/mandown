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

require File.dirname(__FILE__) + '/test_helper.rb'
require File.dirname(__FILE__) + '/../lib/bibdown_lib'

class TestBibdown < Test::Unit::TestCase

  def setup
  end
  
  def test_get_keys_in_order
    # Define a simple plaintext containing citations and an array of the
    # expected keys.
    pt = 'A B C cite:R1 D E cite:R2 F G cite:R1 H I cite:R3 J K cite:R2'
    expected = ['R1', 'R2', 'R3']
    assert_equal(expected, get_keys_in_order(pt))
  end
  
  def test_r_norm
    assert_equal('Hello', r_norm('Hello'))
  end
  
  def test_r_ital
    assert_equal('*Hello*', r_ital('Hello'))
  end
  
  def test_get_first_author_surname
    bibentry = {'authors' => 'Jones, A. B. & Jeffries, C. D.'}
    assert_equal('jones', get_first_author_surname(bibentry))
  end
  
  def test_make_initials
    assert_equal(['A.', 'G.'], make_initials('Alexander Graham'))
  end
  
  def test_make_author_string
    authors = 'Jones, Anthony Bob & Jeffries, Chris David & Jays, Anne May'

    expected__initials_surname_last =
      'A. B. Jones, C. D. Jeffries and A. M. Jays'
    assert_equal(expected__initials_surname_last,
      make_author_string(authors, use_initials=true, surname_first=false))
    
    expected__initials_surname_first =
      'Jones, A. B., Jeffries, C. D. and Jays, A. M.'
    assert_equal(expected__initials_surname_first,
      make_author_string(authors, use_initials=true, surname_first=true))
    
    expected__full_surname_last =
      'Anthony Bob Jones, Chris David Jeffries and Anne May Jays'
    assert_equal(expected__full_surname_last,
      make_author_string(authors, use_initials=false, surname_first=false))
      
    expected__full_surname_first =
      'Jones, Anthony Bob, Jeffries, Chris David and Jays, Anne May'
    assert_equal(expected__full_surname_first,
      make_author_string(authors, use_initials=false, surname_first=true))
  end
  
  def test_check_missing_citations
    none_missing = 'No citations are missing.'
    assert_equal([], check_missing_citations(none_missing))
    
    some_missing = 'There are cite:Missing1 two missing citations cite:Missing2'
    assert_equal(
      ['The following reference key was undefined: Missing1',
        'The following reference key was undefined: Missing2'],
      check_missing_citations(some_missing))
  end
  
  def test_has_key?
    bib_entries = [{:key => 'key1'}]
    assert_equal(true, has_key?('key1', bib_entries))
    assert_equal(false, has_key?('missing_key', bib_entries))
  end

end
