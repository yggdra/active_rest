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
end

describe Company, :schema do
  before(:each) do
    @schema = Company.schema
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

  it 'has a :type_symbolized key' do
    @schema.should have_key(:type)
  end

  it 'has the proper :type_symbolized key' do
    @schema[:type_symbolized].should == :company
  end

  it 'has a :object_actions key' do
    @schema.should have_key(:object_actions)
  end

  it 'has a :class_actions key' do
    @schema.should have_key(:class_actions)
  end

  it 'has a :class_perms key' do
    @schema.should have_key(:class_perms)
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

      it 'has a :edit_on_creation key' do
        pending
      end

      it ':edit_on_creation is false' do
        pending
      end

      it 'has a :visible_on_creation key' do
        pending
      end

      it ':visible_on_creation is false' do
        pending
      end

      it 'has a :after_creation_perms key' do
        pending
      end

      it ':after_creation_perms is a Hash' do
        pending
      end

      it ':after_creation_perms => :read is true' do
        pending
      end

      it ':after_creation_perms => :write is false' do
        pending
      end
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

    # :zip ###############
    describe ':zip key' do
      it 'exists' do
        @attrs.should have_key(:zip)
      end

      it 'has a :type of string' do
        @attrs[:zip][:type].should == :string
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

describe Company, :export_as_hash do
  before(:each) do
    @c1 = Factory(:company_1)
    @c = Factory(:company_complex)
    @ch = @c.export_as_hash
  end

  it 'produces a Hash as result' do
    @ch.should be_kind_of(Hash)
  end

  it 'has the proper :type key' do
    @ch[:_type].should == 'Company'
  end

  it 'has the proper :type_symbolized key' do
    @ch[:_type_symbolized].should == :company
  end
# Add check to see if namespaced types are converted properly

  it ':id key is an integer' do
    @ch[:id].should be_kind_of(Integer)
  end

  it ':name key is a string' do
    @ch[:name].should be_kind_of(String)
  end

  it ':zip key is a string' do
    @ch[:zip].should be_kind_of(String)
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
    @ch[:city].should == 'Seveso'
    @ch[:street].should == 'Via Mezzera 29/A'
    @ch[:zip].should == '20030'
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
      @c1.export_as_hash[:location].should be_nil
    end
  end

  # :phones ###############
  describe ':phones key' do
    it 'is of type Array' do
      @ch[:phones].should be_kind_of(Array)
    end

    it 'has 2 elements' do
      @ch[:phones].should have(2).elements
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

  # :owned_objects ###############
  describe ':owned_objects' do
    it 'does not include embedded polymorphic reference collection' do
      @ch.should_not have_key(:owned_objects)
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

    it 'has :address key' do
      @ch[:full_address].should have_key(:address)
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

  it 'outputs object permissions when :with_perms option is present' do
    @c.export_as_hash(:with_perms => true).should have_key(:_object_perms)
  end

  it 'outputs attribute permissions when :with_perms option is present' do
   @c.export_as_hash(:with_perms => true).should have_key(:_attr_perms)
  end
end

describe Company, :export_as_yaml do

  it 'produces a String as result' do
    Factory(:company_1).export_as_yaml.should be_kind_of(String)
  end
end

describe Company, :nested_attribute do
  it 'finds not nested attribute' do
    pending
  end

  it 'finds nested attribute' do
    pending
  end

  it 'raises an exception if attribute is not found' do
    pending
  end

  it 'raises an exception if relation is not found' do
    pending
  end
end
