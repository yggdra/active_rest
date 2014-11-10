require 'spec_helper'

describe Company do
  it 'creates a new instance given valid attributes' do
    Company.create!({
      :name => 'value for name',
      :city => 'value for city',
      :street => 'value for street',
      :zip => 'value for zip'
    })
  end

  describe :nested_attribute do
    it 'finds not nested attribute' do
      (na, path) = Company.nested_attribute('id')

      na.should_not be_nil
      na.name.should == 'id'
      path.should == []
    end

    it 'finds nested attribute (first level)' do
      (na, path) = Company.nested_attribute('location.raw_name')

      na.should_not be_nil
      na.name.should == 'raw_name'
      path.should == [ :location ]
    end

    it 'finds nested attribute (second level)' do
      (na, path) = Company.nested_attribute('location.coordinate.lat')

      na.should_not be_nil
      na.name.should == 'lat'
      path.should == [ :location, :coordinate ]
    end

    it 'raises UnknownField exception if not nested attribute is not found' do
      lambda { (na, path) = Company.nested_attribute('foobar') }.should raise_error(ActiveRest::Model::UnknownField)
    end

    it 'raises UnknownRelation exception if nested attribute\'s relation is not found' do
      lambda { (na, path) = Company.nested_attribute('foobar.dsf') }.should raise_error(ActiveRest::Model::UnknownRelation)
    end

    it 'raises UnknownField exception if nested attribute is not found in an existing relation' do
      lambda { (na, path) = Company.nested_attribute('location.dsf') }.should raise_error(ActiveRest::Model::UnknownField)
    end
  end

  describe 'interface :rest' do
    before(:each) do
      @interface_rest = Company.interfaces[:rest]
    end

    describe :schema do
      before(:each) do
        @schema = @interface_rest.schema
      end

      it 'produces a Hash as result' do
        @schema.should be_kind_of(Hash)
      end

      it 'has a :type key' do
        @schema.should have_key(:type)
      end

      it 'has the proper :type key' do
        @schema[:type].should == 'Company'
      end

      it 'has a :actions key' do
        @schema.should have_key(:actions)
      end

      it 'has a :attrs key' do
        @schema.should have_key(:attrs)
      end

      describe ':attrs key' do
        before(:each) do
          @attrs = @schema[:attrs]
        end

        it 'is a Hash' do
          @attrs.should be_kind_of(Hash)
        end

        # :id ###############
        describe ':id key' do
          it 'exists' do
            @attrs.should have_key(:id)
          end

          it 'has a :type key' do
            @attrs[:id].should have_key(:type)
          end

          it ':type is integer' do
            @attrs[:id][:type].should == :integer
          end

  #        it 'has a :edit_on_creation key' do
  #          pending
  #        end
  #
  #        it ':edit_on_creation is false' do
  #          pending
  #        end
  #
  #        it 'has a :visible_on_creation key' do
  #          pending
  #        end
  #
  #        it ':visible_on_creation is false' do
  #          pending
  #        end
  #
  #        it 'has a :after_creation_perms key' do
  #          pending
  #        end
  #
  #        it ':after_creation_perms is a Hash' do
  #          pending
  #        end
  #
  #        it ':after_creation_perms => :read is true' do
  #          pending
  #        end
  #
  #        it ':after_creation_perms => :write is false' do
  #          pending
  #        end
        end

        # :name ###############
        describe ':name key' do
          it 'exists' do
            @attrs.should have_key(:name)
          end

          it 'has a :type of string' do
            @attrs[:name][:type].should == :string
          end

          it 'has a :human_name of "Nome"' do
            @attrs[:name][:human_name].should == "Nome"
          end
        end

        # :is_active ###############
        describe ':is_active key' do
          it 'exists' do
            @attrs.should have_key(:is_active)
          end

          it 'has a :type of string' do
            @attrs[:is_active][:type].should == :boolean
          end
        end

        # :excluded_attribute ###############
        describe ':excluded_attribute key' do
          it 'is not present since it is excluded' do
            @attrs.should_not have_key(:excluded_attribute)
          end
        end

        # :not_readable_attribute ###############
        describe ':not_readable_attribute key' do
          it 'is present' do
            @attrs.should have_key(:not_readable_attribute)
          end

          it 'has a :type of integer' do
            @attrs[:not_readable_attribute][:type].should == :integer
          end

          it 'is not readable' do
            expect(@attrs[:not_readable_attribute][:readable]).to be_falsey
          end

          it 'is writable' do
            @attrs[:not_readable_attribute][:writable].should be_truthy
          end
        end

        # :not_writable_attribute ###############
        describe ':not_writable_attribute key' do
          it 'is present' do
            @attrs.should have_key(:not_writable_attribute)
          end

          it 'has a :type of integer' do
            @attrs[:not_writable_attribute][:type].should == :integer
          end

          it 'is readable' do
            @attrs[:not_writable_attribute][:readable].should be_truthy
          end

          it 'is not writable' do
            @attrs[:not_writable_attribute][:writable].should be_falsey
          end
        end

        # :created_at ###############
        describe ':created_at key' do
          it 'exists' do
            @attrs.should have_key(:created_at)
          end

          it 'has a :type of timestamp' do
            @attrs[:created_at][:type].should == :timestamp
          end
        end

        # :location ###############
        describe ':location key' do
          it 'exists' do
            @attrs.should have_key(:location)
          end

          it 'is a Hash' do
            @attrs[:location].should be_kind_of(Hash)
          end

          it 'has a :type of :embedded_model' do
            @attrs[:location][:type].should == :embedded_model
          end

          describe ':schema key' do
            it 'exists' do
              @attrs[:location].should have_key(:schema)
            end

            it 'is a Hash' do
              @attrs[:location][:schema].should be_kind_of(Hash)
            end

            it 'has a :type of CompanyLocation' do
              @attrs[:location][:schema][:type].should == 'CompanyLocation'
            end

            it 'has a :attrs key' do
              @attrs[:location][:schema].should have_key(:attrs)
            end

            it 'has a :attrs key of type Hash' do
              @attrs[:location][:schema][:attrs].should be_kind_of(Hash)
            end
          end
        end

        # :phones ###############
        describe ':phones key' do
          it 'exists' do
            @attrs.should have_key(:phones)
          end

          it 'has a :type of :uniform_models_collection' do
            @attrs[:phones][:type].should == :uniform_models_collection
          end

          it 'has a :human_name of "Nome"' do
            @attrs[:phones][:human_name].should == 'Phone numbers'
          end

          it 'has a :schema key' do
            @attrs[:phones].should have_key(:schema)
          end

          describe ':schema key' do
            it 'is a Hash' do
              @attrs[:phones][:schema].should be_kind_of(Hash)
            end

            it 'has a :type of Company::Phone' do
              @attrs[:phones][:schema][:type].should == 'Company::Phone'
            end

            it 'has a :attrs key' do
              @attrs[:phones][:schema].should have_key(:attrs)
            end

            it 'has a :attrs key of type Hash' do
              @attrs[:phones][:schema][:attrs].should be_kind_of(Hash)
            end
          end
        end

        # :users ###############
        describe ':users key' do
          it 'exists' do
            @attrs.should have_key(:users)
          end

          it 'has a :type of :uniform_references_collection' do
            @attrs[:users][:type].should == :uniform_references_collection
          end

          it 'has a :referenced_class key' do
            @attrs[:users].should have_key(:referenced_class)
          end

          it ':referenced_class is User' do
            @attrs[:users][:referenced_class].should == 'User'
          end
        end

        # :group ###############
        describe ':group key' do
          it 'exists' do
            @attrs.should have_key(:group)
          end

          it 'has a :type of :reference' do
            @attrs[:group][:type].should == :reference
          end

          it 'has a :referenced_class key' do
            @attrs[:group].should have_key(:referenced_class)
          end

          it ':referenced_class is User' do
            @attrs[:group][:referenced_class].should == 'Group'
          end
        end

        # :object_1 ###############
        it 'contains :objects_1 key' do
          @attrs.should have_key(:object_1)
        end

        describe ':object_1 key' do
          it 'has a :type of :embedded_polymorphic_model' do
            @attrs[:object_1][:type].should == :embedded_polymorphic_model
          end
        end

        # :object_2 ###############
        it 'contains :objects_1 key' do
          @attrs.should have_key(:object_2)
        end

        describe ':object_2 key' do
          it 'has a :type of :embedded_polymorphic_model' do
            @attrs[:object_2][:type].should == :embedded_polymorphic_model
          end
        end

        # :polyref_1 ###############
        it 'contains :polyref_1 key' do
          @attrs.should have_key(:polyref_1)
        end

        describe ':polyref_1 key' do
        end

        # :polyref_2 ###############
        it 'contains :polyref_2 key' do
          @attrs.should have_key(:polyref_2)
        end

        describe ':polyref_2 key' do
        end

        # :full_address ###############
        it 'contains :full_address key' do
          @attrs.should have_key(:full_address)
        end

        describe ':full_address key' do
          it 'has a :type of :structure' do
            @attrs[:full_address][:type].should == :structure
          end
        end

        # :virtual ###############
        it 'contains :virtual key' do
          @attrs.should have_key(:virtual)
        end

        describe ':virtual key' do
          it 'has a :type of :string' do
            @attrs[:virtual][:type].should == :string
          end
        end
      end
    end

    describe 'ar_serializable_hash' do
      before(:each) do
        @c1 = FactoryGirl.create(:company_1)
        @c = FactoryGirl.create(:company_complex)
        @ch = @c.ar_serializable_hash(:rest)
      end

      it 'produces a Hash as result' do
        @ch.should be_kind_of(Hash)
      end

      it 'has the proper :type key' do
        @ch[:_type].should == 'Company'
      end

    # Add check to see if namespaced types are converted properly

      it ':id key is an integer' do
        @ch[:id].should be_kind_of(Integer)
      end

      it ':name key is a string' do
        @ch[:name].should be_kind_of(String)
      end

      it ':is_active key is a boolean' do
        @ch[:is_active].should be_kind_of(TrueClass)
      end

      it ':created_at key should be of type ActiveSupport::TimeWithZone' do
        @ch[:created_at].should be_kind_of(ActiveSupport::TimeWithZone)
      end

      it 'simple attributes\' values should be correct' do
        @ch[:id].should == 4
        @ch[:name].should == 'Huge Corp Corp.'
        @ch[:is_active].should == true
      end

      describe ':location key' do
        it ':location is of type Hash if present' do
          @ch[:location].should be_kind_of(Hash)
        end

        it ':location has the right keys' do
          @ch[:location].should have_key(:lat)
          @ch[:location].should have_key(:lon)
          @ch[:location].should have_key(:raw_name)
        end

        it ':location is nil if not present' do
          @c1.ar_serializable_hash(:rest)[:location].should be_nil
        end
      end

      # :phones ###############
      describe ':phones key' do
        it 'is of type Array' do
          @ch[:phones].should be_kind_of(Array)
        end

        it 'has 2 elements' do
          expect(@ch[:phones].size).to eq(2)
        end

        it 'elements are of type Company::Phone' do
          @ch[:phones][0][:_type].should == 'Company::Phone'
          @ch[:phones][1][:_type].should == 'Company::Phone'
        end
      end

      # :users ###############
      it 'does not include reference collections' do
        @ch.should_not have_key(:users)
      end

      # :group ###############
      it 'does not include references' do
        @ch.should_not have_key(:group)
      end

      # :object_1 ###############
      describe ':object_1 key' do
        it 'exists' do
          @ch.should have_key(:object_1)
        end

        it 'is of type Company::Foo' do
          @ch[:object_1][:_type].should == 'Company::Foo'
        end
      end

      # :object_2 ###############
      describe ':object_2 key' do
        it 'exists' do
          @ch.should have_key(:object_2)
        end

        it 'is of type Company::Bar' do
          @ch[:object_2][:_type].should == 'Company::Bar'
        end
      end

      # :full_address ###############
      describe ':full_address key' do
        it 'exists' do
          @ch.should have_key(:full_address)
        end

        it 'is a Hash' do
          @ch[:full_address].should be_a(Hash)
        end

        it 'has :street key' do
          @ch[:full_address].should have_key(:street)
        end
      end

      # :virtual ###############
      describe ':virtual key' do
        it 'exists' do
          @ch.should have_key(:virtual)
        end

        it 'is a String' do
          @ch[:virtual].should be_a(String)
        end

        it 'has the correct value' do
          @ch[:virtual].should == 'This is the virtual value'
        end
      end

    # Add check to see if Object attributes are converted properly

      it 'does not output object permissions when :with_perms option is missing' do
        @ch.should_not have_key(:attr_perms)
      end

      it 'does not output attribute permissions when :with_perms option is missing' do
        @ch.should_not have_key(:attr_perms)
      end
    end

    describe :apply_update_attributes do
      before(:each) do
        @c1 = FactoryGirl.create(:company_1)
        @c = FactoryGirl.create(:company_complex)
        @g2 = FactoryGirl.create(:group_2)
      end

      it 'sets basic attributes' do
        @c.name.should_not == 'This Is The New Name'
        @interface_rest.apply_update_attributes(@c, { :name => 'This Is The New Name' })
        @c.name.should == 'This Is The New Name'
      end

      describe 'Reference' do
        it 'sets record when it was nil' do
          @c1.group.should be_nil
          @interface_rest.apply_update_attributes(@c1, { :group => { :id => @g2.id } })
          @c1.save!
          @c1.group.should_not be_nil
          @c1.group.name.should == @g2.name
        end

        it 'sets record when it was nil ignoring other parameters' do
          @c1.group.should be_nil
          @interface_rest.apply_update_attributes(@c1, { :group => { :id => @g2.id, :name => 'FooBar' } })
          @c1.save!
          @c1.group.should_not be_nil
          @c1.group.name.should == @g2.name
        end

        it 'set value to nil from existing record' do
          @c.group.should_not be_nil
          @interface_rest.apply_update_attributes(@c, { :group => nil })
          @c.save!
          @c.group.should be_nil
        end
      end

      describe 'PolymorphicReference' do
        it 'sets record when it was nil' do
          @c1.polyref_1.should be_nil
          @interface_rest.apply_update_attributes(@c1, { :polyref_1 => { :_type => @g2.class.name, :id => @g2.id } })
          @c1.save!
          @c1.polyref_1.should_not be_nil
          @c1.polyref_1.class.should == @g2.class
          @c1.polyref_1.name.should == @g2.name
        end

        it 'sets record when it was nil ignoring other attributes' do
          @c1.polyref_1.should be_nil
          @interface_rest.apply_update_attributes(@c1, { :polyref_1 => { :_type => @g2.class.name, :id => @g2.id, :name => 'FooBar' } })
          @c1.save!
          @c1.polyref_1.should_not be_nil
          @c1.polyref_1.class.should == @g2.class
          @c1.polyref_1.name.should == @g2.name
        end

        it 'set value to nil from existing record' do
          @c.polyref_1.should_not be_nil
          @interface_rest.apply_update_attributes(@c, { :polyref_1 => nil })
          @c.save!
          @c.polyref_1.should be_nil
        end
      end

      describe 'EmbeddedModel' do
        it 'sets record when it was nil' do
          @c1.location.should be_nil
          @interface_rest.apply_update_attributes(@c1, { :location => { :raw_name => 'Foobar Foo Bar' } })
          @c1.save!
          @c1.location.should_not be_nil
          @c1.location.raw_name.should == 'Foobar Foo Bar'
        end

        it 'set value to nil from existing record' do
          @c.location.should_not be_nil
          @interface_rest.apply_update_attributes(@c, { :location => nil })
          @c.save!
          @c.location.should be_nil
        end

        it 'updates record' do
          @c.location.should_not be_nil
          @interface_rest.apply_update_attributes(@c, { :location => { :raw_name => 'Foobar Foo Bar' } })
          @c.save!
          @c.location.should_not be_nil
          @c.location.raw_name.should == 'Foobar Foo Bar'
        end
      end

      describe 'PolymorphicEmbeddedModel' do
        it 'sets record when it was nil' do
          @c1.object_1.should be_nil
          @interface_rest.apply_update_attributes(@c1, { :object_1 => { :_type => 'Group', :name => 'This group' } })
          @c1.save!
          @c1.object_1.should_not be_nil
          @c1.object_1.class.should == Group
          @c1.object_1.name.should == 'This group'
        end

        it 'set value to nil from existing record' do
          @c.object_1.should_not be_nil
          @interface_rest.apply_update_attributes(@c, { :object_1 => nil })
          @c.save!
          @c.object_1.should be_nil
        end

        it 'updates record' do
          @c.object_1.should_not be_nil
          @interface_rest.apply_update_attributes(@c, { :object_1 => { :name => 'Foobar Foo Bar' } })
          @c.save!
          @c.object_1.should_not be_nil
          @c.object_1.class.should == Company::Foo
          @c.object_1.name.should == 'Foobar Foo Bar'
        end
      end

      describe 'UniformModelCollection' do
        it 'adds record' do
          @c.phones.count.should == 2
          @interface_rest.apply_update_attributes(@c, { :phones => [ { :number => '555-5555' } ] })
          @c.phones.count.should == 3
          @c.phones.last.number.should == '555-5555'
        end

        it 'updates record' do
          cnt = @c.phones.count
          @interface_rest.apply_update_attributes(@c, { :phones => [ { :id => 1001, :number => '555-1234' } ] })
          @c.save!
          @c.phones.count.should == cnt
          @c.phones.find(1001).number.should == '555-1234'
        end

        it 'raises a ActiveRest::Model::Interface::AssociatedRecordNotFound exception trying to update an unexistant record' do
          lambda { @interface_rest.apply_update_attributes(@c, { :phones => [ { :id => 93287376 } ] }) }.should raise_error(
            ActiveRest::Model::Interface::AssociatedRecordNotFound)
        end

        it 'removes record' do
          @c.phones.count.should == 2
          @interface_rest.apply_update_attributes(@c, { :phones => [ { :id => 1001, :_destroy => true } ] })
          @c.save!
          @c.phones.count.should == 1
          @c.phones.collect(&:number).should_not include(1001)
        end

        it 'raises a ActiveRest::Model::Interface::AssociatedRecordNotFound exception trying to remove an unexistant record' do
          lambda { @interface_rest.apply_update_attributes(@c, { :phones => [ { :id => 38247642, :_destroy => true } ] }) }.should raise_error(
            ActiveRest::Model::Interface::AssociatedRecordNotFound)
        end
      end

      describe 'UniformReferenceCollection' do
        it 'adds record' do
          @u = FactoryGirl.create(:user, :name => 'QuiQuoQua', :id => 2000)

          @c.users.count.should == 2
          @interface_rest.apply_update_attributes(@c, { :users => [ { :id => 2000 } ] })
          @c.save!
          @c.users.count.should == 3
          @c.users.last.name.should == 'QuiQuoQua'
        end

        it 'raises a ActiveRest::Model::Interface::AssociatedRecordNotFound exception trying to remove an unexistant record' do
          lambda { @interface_rest.apply_update_attributes(@c, { :users => [ { :id => 3284234, :_destroy => true } ] }) }.should raise_error(
            ActiveRest::Model::Interface::AssociatedRecordNotFound)
        end

        it 'removes record' do
          @c.users.count.should == 2
          @interface_rest.apply_update_attributes(@c, { :users => [ { :id => 1001, :_destroy => true } ] })
          @c.save!
          @c.users.count.should == 1
          @c.phones.collect(&:number).should_not include(1001)
        end
      end
    end
  end
end
