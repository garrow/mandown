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
require File.dirname(__FILE__) + '/../lib/secdown_lib'

class TestSecdown < Test::Unit::TestCase

  def setup
  end
  
  def test_atx_header?
    assert_equal(true, atx_header?('# This is a header'))
    assert_equal(true, atx_header?('## This is a header'))
    assert_equal(true, atx_header?('#### This is a header'))
    assert_equal(false, atx_header?('This is not a header'))
    assert_equal(false, atx_header?(''))
  end
  
  def test_get_atx_nesting_level
    assert_equal(0, get_atx_nesting_level('This is not a header.'))
    assert_equal(1, get_atx_nesting_level('# This is a level 1 header'))
    assert_equal(2, get_atx_nesting_level('## This is a level 2 header'))
    assert_equal(3, get_atx_nesting_level('### This is a level 3 header'))
    assert_equal(4, get_atx_nesting_level('#### This is a level 4 header'))
    assert_equal(5, get_atx_nesting_level('##### This is a level 5 header'))
    assert_equal(6, get_atx_nesting_level('###### This is a level 6 header'))        
  end

  def test_all_chars?
    assert_equal(true, all_chars?('======', '='))
    assert_equal(false, all_chars?('== Hello', '='))
    assert_equal(false, all_chars?('=======', '-'))
  end

  def test_setx_to_atx
    source = [
      "This is just a line.",
      "",
      "This is a level 1 header",
      "==========================",
      "",
      "This is a level 2 header",
      "--------------------------",
      "",
      "And this is some text."]
    expected = [
      "This is just a line.",
      "",
      "# This is a level 1 header",
      "",
      "## This is a level 2 header",
      "",
      "And this is some text."]
    
    assert_equal(expected, setx_to_atx(source))
  end

  def test_get_heading_level_string
    assert_equal('1.1', get_heading_level_string(2, '1'))
    assert_equal('3', get_heading_level_string(1, '2.1'))
    assert_equal('2.2', get_heading_level_string(2, '2.1'))
    assert_equal('2.1.3', get_heading_level_string(3, '2.1.2'))
    assert_equal('3', get_heading_level_string(1, '2.1.1'))
  end

  def test_get_next_level_string
    assert_equal('2', get_next_level_string('1', '# Level 1 header'))
    assert_equal('1.1', get_next_level_string('1', '## Level 1.1 header'))
    assert_equal('2.2', get_next_level_string('2.1', '## Level 2.2 header'))
    assert_equal('2.1.3', get_next_level_string('2.1.2', '### A 2.1.3 header'))
  end

  def test_insert_level_to_atx_header
    assert_equal('# 1 Title', insert_level_to_atx_header('1', '# Title'))
  end

  def test_insert_header_levels
    source = [
      "This is just a line.",
      "",
      "This is a level 1 header",
      "========================",
      "",
      "## This is a level 2 header",
      "",
      "# This is another title",
      "",
      "And this is some text",
      "",
      "Another header",
      "--------------",
      "",
      "More text",
      "",
      "## Yet another header."]
    expected = [
      "This is just a line.",
      "",
      "# 1 This is a level 1 header",
      "",
      "## 1.1 This is a level 2 header",
      "",
      "# 2 This is another title",
      "",
      "And this is some text",
      "",
      "## 2.1 Another header",
      "",
      "More text",
      "",
      "## 2.2 Yet another header."]
    assert_equal(expected, insert_header_levels(source))
    
    source = [
      "This is a heading",
      "=================",
      "",
      "And this is some text."]
    expected = [
      "# 1 This is a heading",
      "",
      "And this is some text."]
    assert_equal(expected, insert_header_levels(source))
    
    # Test that it ignores bibliography headings by default.
    bib_line = ["# Bibliography"]
    assert_equal(bib_line, insert_header_levels(bib_line))
  end
  
  def test_get_section_number_from_header
    assert_equal('2', get_section_number_from_header('# 2 Some Header'))
    assert_equal('2.1', get_section_number_from_header('## 2.1 Some Header'))
    assert_equal('1.2.3', get_section_number_from_header('### 1.2.3 Header'))
  end
  
  
  def test_replace_section_references
    source = [
      '# 1 First Heading',
      '',
      'This is a reference to the third heading label sec:lab3.',
      '',
      '# 2 Second Heading',
      '',
      'label:lab2',
      '',
      'This is a reference to sec:lab2.',
      '',
      '## 2.1 A subheading',
      '',
      'label:lab2.1',
      '',
      'This is a reference to the first label in sec:lab2.',
      'This is a reference the second label in sec:lab2, sec:lab2.1.',
      '',
      '# 3 Third heading',
      '',
      'label:lab3']
    
      expected = [
        '# 1 First Heading',
        '',
        'This is a reference to the third heading label section 3.',
        '',
        '# 2 Second Heading',
        '',
        '',
        'This is a reference to section 2.',
        '',
        '## 2.1 A subheading',
        '',
        '',
        'This is a reference to the first label in section 2.',
        'This is a reference the second label in section 2, section 2.1.',
        '',
        '# 3 Third heading',
        '']
      assert_equal(expected, replace_section_references(source))
      
      source = [
        '# 1 Heading',
        'label:lab1',
        '',
        'In Sec:lab1 we saw ...']
      expected = [
        '# 1 Heading',
        '',
        'In Section 1 we saw ...']
      assert_equal(expected, replace_section_references(source))    

      source = [
        '# 1 Heading',
        'label:lab1',
        '',
        'In §:lab1 we saw ...']
      expected = [
        '# 1 Heading',
        '',
        'In §1 we saw ...']
      assert_equal(expected, replace_section_references(source))

  end
  
  
end
