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
require File.dirname(__FILE__) + '/../lib/eqndown_lib'

class TestEqndown < Test::Unit::TestCase

  def setup
  end
  
  def test_extract_eqn_text
    source = 'This is some text. This is an equation $y=(x+1)/2$.'
    expected = ['y=(x+1)/2']
#    assert_equal(expected, extract_eqn_text(source))
    
    source = 'Two equations on one line: $y=(x+1)/2$ and $y = x-1$.'
    expected = ['y=(x+1)/2', 'y = x-1']
    assert_equal(expected, extract_eqn_text(source))
  end
  

end
