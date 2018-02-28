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

class Trust::Controller::ResourceTest < ActiveSupport::TestCase


  setup do
    module ::NameSpacedResource

      class MyEntity
      end

      class Person
      end
    end

    class ::Parent
      def initialize(*args)
        
      end
    end
    class ::Child < Parent; end
    class ::Baluba < Parent; end
    class ::GrandChild < Child; end
  end


  context 'Info classes' do
    context 'Instance' do
      setup do
        @res = Trust::Controller::Resource::ResourceInfo.new('name_spaced_resource/my_entities', {:name_spaced_resource_my_entity => 'cool'})
      end

      should 'resolve name' do
        assert_equal :name_spaced_resource_my_entity, @res.name
      end
      should 'resolve plural name' do
        assert_equal :name_spaced_resource_my_entities, @res.plural_name
      end
      should 'resolve path' do
        assert_equal 'name_spaced_resource/my_entities', @res.path
      end
      should 'resolve class' do
        assert_equal NameSpacedResource::MyEntity, @res.klass
      end

      should 'resolve parameter' do
        assert_equal 'cool', @res.params
      end
      context 'collection' do
        should 'return array where parent represented' do
          parent = stub('parent', :object => 12)
          @res.expects(:association_name).with(parent).returns(15)
          assert_equal [12, 15], @res.collection(parent)
        end
        should 'return class where no parent' do
          assert_equal NameSpacedResource::MyEntity, @res.collection(nil)
        end
        should 'return with instance if present' do
          parent = stub('parent', :object => 12)
          @res.expects(:association_name).never
          assert_equal [12, 15], @res.collection(parent, 15)
        end
      end
    end

    context 'Irregular Instance' do
      setup do
        @res = Trust::Controller::Resource::ResourceInfo.new('name_spaced_resource/people', {:name_spaced_resource_person => 'cool' })
      end

      should 'resolve name' do
        assert_equal :name_spaced_resource_person, @res.name
      end
      should 'resolve plural name' do
        assert_equal :name_spaced_resource_people, @res.plural_name
      end
      should 'resolve path' do
        assert_equal 'name_spaced_resource/people', @res.path
      end
      should 'resolve class' do
        assert_equal NameSpacedResource::Person, @res.klass
      end
      should 'resolve parameter' do
        assert_equal 'cool', @res.params
      end
    end

    context 'Inheritable instance' do
      should 'detect params for children' do
        @res = Trust::Controller::Resource::ResourceInfo.new('parents', {:child => 'cool' })
        assert_equal 'cool', @res.params
      end

      should 'detect params for grandchilds' do
        @res = Trust::Controller::Resource::ResourceInfo.new('parents', {:grand_child => 'cool' })
        assert_equal 'cool', @res.params
      end
      should 'detect params for base' do
        @res = Trust::Controller::Resource::ResourceInfo.new('parents', {:parent => 'cool' })
        assert_equal 'cool', @res.params
      end
      should 'resolve class' do
        @res = Trust::Controller::Resource::ResourceInfo.new('parents', {:grand_child => 'cool' })
        assert_equal Parent, @res.klass
        assert_equal GrandChild, @res.real_class
        @res = Trust::Controller::Resource::ResourceInfo.new('parents', {:parent => 'cool' })
        assert_equal Parent, @res.klass
        assert_equal Parent, @res.real_class
      end
    end

    context 'Parent resource' do
      setup do
        @request = Object.new
        @resources = [NameSpacedResource::Person, :child]
      end
      context 'when found' do
        should 'return object for namespaced resource' do
          @request.stubs(:path_parameters).returns({:name_spaced_resource_person_id => 2 })
          NameSpacedResource::Person.expects(:find).with(2).returns(@object = NameSpacedResource::Person.new)
          @res = Trust::Controller::Resource::ParentInfo.new(@resources, {}, @request)
          assert_equal @object, @res.object
        end
        should 'return object for regular resource' do
          @request.stubs(:path_parameters).returns({:child_id => 2 })
          Child.expects(:find).with(2).returns(@object = Child.new)
          @res = Trust::Controller::Resource::ParentInfo.new(@resources, {}, @request)
          assert_equal @object, @res.object
        end
        context 'the attributes' do
          setup do
            @request.stubs(:path_parameters).returns({:child_id => 2 })
            Child.expects(:find).with(2).returns(@object = Child.new)
            @res = Trust::Controller::Resource::ParentInfo.new(@resources, {:child => 'tie'}, @request)
          end
          should 'return class for object' do
            assert_equal @object, @res.object
            assert @res.object?        
          end
          should 'respond to object?' do
            assert @res.object?        
          end
          should 'return name for class' do
            assert_equal :child, @res.name
          end
          should 'return parameters' do
            assert_equal 'tie', @res.params
          end
        end
      end
      should 'return nil for object if not found' do
        @request.stubs(:path_parameters).returns({:child_id => 2 })
        Child.expects(:find).with(2).returns(nil)
        @res = Trust::Controller::Resource::ParentInfo.new(@resources, {}, @request)
        assert_nil @res.object
        assert !@res.object?
      end
      should 'return nil for object if not specified' do
        @request.stubs(:path_parameters).returns({})
        @res = Trust::Controller::Resource::ParentInfo.new(@resources, {}, @request)
        assert_nil @res.object
        assert !@res.object?
      end
      should 'return nil for klass when not found' do
        @request.stubs(:path_parameters).returns({})
        @res = Trust::Controller::Resource::ParentInfo.new(@resources, {}, @request)
        assert_nil @res.klass
      end
    end

    context 'Parent resource with inheritance' do
      setup do
        @request = Object.new
        @resources = [:parent]
        @request.stubs(:path_parameters).returns({:child_id => 2 })
        Parent.expects(:find).with(2).returns(@object = Child.new)
        @res = Trust::Controller::Resource::ParentInfo.new(@resources, {}, @request)
      end
      should 'resolve descendants' do
        assert_equal @object, @res.object
      end
      should 'have correct name' do
        assert_equal :child, @res.name
      end
      should 'have correct class' do
        assert_equal Parent, @res.klass
      end
      should 'have real class' do
        assert_equal Child, @res.real_class
      end
    end
  end
  
  
  context 'Resource' do
    setup do
      @controller = stub('Controller', :controller_path => :controller)
      @properties = Trust::Controller::Properties.new(@controller, nil)
      @properties.model :child
      @properties.belongs_to :parent
      @resource_info = stub('ResourceInfo')
      @parent_info = stub(:object => 6, :name => :parent)
      @resource_info.stubs(:name).returns(:child)
    end
    context 'Plain' do
      setup do
        Trust::Controller::Resource.any_instance.expects(:extract_resource_info).with('child', {}).returns(@resource_info)
        Trust::Controller::Resource.any_instance.expects(:extract_parent_info).with({:parent => nil}, {}, @request).returns(@parent_info)
        @resource = Trust::Controller::Resource.new(@controller, @properties, 'new',{}, @request)      
      end
      should 'discover variable names' do
        @resource_info.expects(:plural_name).returns(:children)
        assert_equal :child, @resource.send(:instance_name)
        assert_equal :parent, @resource.send(:parent_name)
        assert_equal :children, @resource.send(:plural_instance_name)
      end
      should 'have access to instances' do
        @resource.expects(:plural_instance_name).twice.returns(:children)
        @resource.instances = [1]
        assert_equal [1], @resource.instances
        assert_equal [1], @controller.instance_variable_get(:@children)
      end
      should 'have access to instantiated' do
        @resource.expects(:instances).returns(1)
        assert_equal 1, @resource.instantiated
        @resource.expects(:instances).returns(nil)
        @resource.expects(:instance).returns(2)
        assert_equal 2, @resource.instantiated
      end
      should 'provide access to nested' do
        @resource.expects(:parent).twice.returns(:parent)
        @resource.expects(:instance).returns(:instance)
        assert_equal [:parent, :instance], @resource.nested
        @resource.expects(:parent).returns(nil)
        @resource.expects(:instance).returns(:instance)
        assert_equal :instance, *@resource.nested
      end
      should 'provide collection' do
        @resource_info.expects(:collection).with(@parent_info, nil).returns(1)
        assert_equal 1, @resource.collection
        @resource_info.expects(:collection).with(@parent_info, 2).returns(3)
        assert_equal 3, @resource.collection(2)
      end
      should 'load as expected' do
        @resource_info.expects(:relation).with(@parent_info).returns(Child)
        @resource.expects(:new_action?).returns(true).at_least_once
        @resource_info.stubs(:params).returns({})
        @controller.expects(:respond_to?).with(:build,true).returns(false)
        @resource.load
        assert_equal 6, @controller.instance_variable_get(:@parent)
        assert_equal 6, @resource.parent
        assert @controller.instance_variable_get(:@child).is_a?(Child)
        assert @resource.instance.is_a?(Child)
      end
    end
    context 'Actions' do
      setup do
        Trust::Controller::Resource.any_instance.expects(:extract_resource_info).with('child', { :id => 1 }).returns(@resource_info)
        Trust::Controller::Resource.any_instance.expects(:extract_parent_info).with({:parent => nil}, { :id => 1 }, @request).returns(@parent_info)
      end
      should 'load member as expected' do
        @resource = Trust::Controller::Resource.new(@controller, @properties, 'member',{ :id => 1 }, @request)
        @resource_info.expects(:relation).with(@parent_info).returns(Child)
        @properties.actions :member => [:member]
        @resource_info.stubs(:params).returns({})
        @resource.expects(:new_action?).returns(false).at_least_once
        @controller.expects(:respond_to?).with(:build,true).returns(false)
        Child.expects(:find).with(1).returns(Child.new)
        @resource.load
        assert_equal 6, @controller.instance_variable_get(:@parent)
        assert_equal 6, @resource.parent
        assert @controller.instance_variable_get(:@child).is_a?(Child)
        assert @resource.instance.is_a?(Child)
      end
      should 'discovered collection_action? as a method' do
        @resource = Trust::Controller::Resource.new(@controller, @properties, 'index',{ :id => 1 }, @request)
        assert @resource.collection_action?
      end
      should 'discovered member_action? as a method' do
        @resource = Trust::Controller::Resource.new(@controller, @properties, 'show',{ :id => 1 }, @request)
        assert @resource.member_action?
      end
      should 'discovered new_action? as a method' do
        @resource = Trust::Controller::Resource.new(@controller, @properties, 'new',{ :id => 1 }, @request)
        assert @resource.new_action?
      end
    end
    context 'Nested resources' do
      setup do
        Trust::Controller::Resource.any_instance.expects(:extract_resource_info).with('child', { :child_id => 1 }).returns(@resource_info)
        Trust::Controller::Resource.any_instance.expects(:extract_parent_info).with({:parent => nil}, { :child_id => 1 }, @request).returns(@parent_info)
      end
      should 'load as expected' do
        @resource = Trust::Controller::Resource.new(@controller, @properties, 'member',{ :child_id => 1 }, @request)
        @properties.actions :member => [:member]
        @resource_info.stubs(:params).returns({})
        @resource_info.expects(:relation).with(@parent_info).returns(Child)
        @controller.expects(:respond_to?).with(:build,true).returns(false)
        Child.expects(:find).with(1).returns(Child.new)
        @resource.load
        assert_equal 6, @controller.instance_variable_get(:@parent)
        assert_equal 6, @resource.parent
        assert @controller.instance_variable_get(:@child).is_a?(Child)
        assert @resource.instance.is_a?(Child)
      end
    end
  end
  context 'Nested resources of same class' do
    setup do
      @controller = stub('Controller', :controller_path => :controller)
      @properties = Trust::Controller::Properties.new(@controller, nil)
      @properties.model :child
      @properties.belongs_to :child
      @resource_info = stub('ResourceInfo')
      @resource_info.stubs(:object => 6, :name => :child)
      Trust::Controller::Resource.any_instance.expects(:extract_resource_info).with('child', { :child_id => 1 }).returns(@resource_info)
      Trust::Controller::Resource.any_instance.expects(:extract_parent_info).with({:child => nil}, { :child_id => 1 }, @request).returns(@resource_info)
      @resource = Trust::Controller::Resource.new(@controller, @properties, 'member',{ :child_id => 1 }, @request)
    end
    should 'appear as truly nested' do
      assert @resource.send(:truly_nested?)
    end
    should 'support nested instance name' do
      assert_equal :child_child, @resource.instance_name
    end
  end
end
