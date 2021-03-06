# Copyright (c) 2012 Bingo Entreprenøren AS
# Copyright (c) 2012 Teknobingo Scandinavia AS
# Copyright (c) 2012 Knut I. Stenmark
# Copyright (c) 2012 Patrick Hanevold
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'test_helper'

class Trust::ActiveModelTest < ActiveSupport::TestCase
  context 'permits?' do
    setup do
      @user = User.new
      @account = Account.new
    end
    should 'support calls to authorized? on class level' do
      Trust::Authorization.expects(:authorized?).with(:manage,Account,:foo)
      Account.permits? :manage, :foo
    end
    should 'support calls to authorized? on instance' do
      Trust::Authorization.expects(:authorized?).with(:manage,@account,:foo)
      @account.permits? :manage, :foo
    end
    should 'support calls to authorized? with actor specified' do
      Trust::Authorization.expects(:authorized?).with(:manage,Account,:foo, :by => :actor)
      Account.permits? :manage, :foo, :by => :actor
      Trust::Authorization.expects(:authorized?).with(:manage,@account,:foo, :by => :actor)
      @account.permits? :manage, :foo, :by => :actor
    end
    should 'support calls to authorized? with actor specified and no parent' do
      Trust::Authorization.expects(:authorized?).with(:manage,Account, :by => :actor)
      Account.permits? :manage, :by => :actor
      Trust::Authorization.expects(:authorized?).with(:manage,@account, :by => :actor)
      @account.permits? :manage, :by => :actor
    end
  end
  context 'ensure_permitted!' do
    setup do
      @user = User.new
      @account = Account.new
    end
    should 'support calls to athorized! on class level' do
      Trust::Authorization.expects(:authorize!).with(:manage,Account,:foo)
      Account.ensure_permitted! :manage, :foo
    end
    should 'support calls to athorized! on instance' do
      Trust::Authorization.expects(:authorize!).with(:manage,@account,:foo)
      @account.ensure_permitted! :manage, :foo
    end
    should 'support calls to authorized! with actor specified' do
      Trust::Authorization.expects(:authorize!).with(:manage,Account,:foo, :by => :actor)
      Account.ensure_permitted! :manage, :foo, :by => :actor
      Trust::Authorization.expects(:authorize!).with(:manage,@account,:foo, :by => :actor)
      @account.ensure_permitted! :manage, :foo, :by => :actor
    end
    should 'support calls to authorized! with actor specified and no parent' do
      Trust::Authorization.expects(:authorize!).with(:manage,Account, :by => :actor)
      Account.ensure_permitted! :manage, :by => :actor
      Trust::Authorization.expects(:authorize!).with(:manage,@account, :by => :actor)
      @account.ensure_permitted! :manage, :by => :actor
    end
  end
end
