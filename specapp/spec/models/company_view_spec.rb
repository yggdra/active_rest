require 'spec_helper'

module ActiveRest

describe View do

  before(:each) do
    @c1 = FactoryGirl.create(:company_1)
  end

  it 'by default outputs the whole object' do

    v = ActiveRest::View.new(:show) do
    end

    @c1.ar_serializable_hash(:rest, :view => v).should deep_include(
     {
      :id => 1,
      :created_at => @c1.created_at,
      :updated_at => @c1.updated_at,
      :name => 'big_corp',
      :not_writable_attribute => 34567,
      :city => 'NY',
#      :street => 'Fifth Avenue',
#      :zip => '28021',
      :is_active => true,
      :registration_date => @c1.registration_date,
      :group_id => nil,
      :polyref_1 => { :id => nil, :_type => nil },
      :polyref_1_id => nil,
      :polyref_1_type => nil,
      :polyref_2 => { :id => nil, :_type => nil },
      :polyref_2_id => nil,
      :polyref_2_type => nil,
      :phones => [],
      :location => nil,
      :full_address => {
        :street => 'Fifth Avenue',
        :city => 'NY',
        :zip => '28021',
        :_type=> 'Company::FullAddress'
      },
      :object_1 => nil,
      :object_2 => nil,
      :virtual => 'This is the virtual value',
      :_type => 'Company',
     })
  end

end


describe View, 'empty!' do

  before(:each) do
    @c1 = FactoryGirl.create(:company_1)
  end

  it 'removes all attributes' do

    v = ActiveRest::View.new(:show) do
      empty!
    end

    @c1.ar_serializable_hash(:rest, :view => v).should ==
     {
     }
  end

end

describe View, 'attribute' do
  before(:each) do
    @c1 = FactoryGirl.create(:company_1)
    @c = FactoryGirl.create(:company_complex)
  end

  it 'allows showing of hidden attributes' do
    v = ActiveRest::View.new(:show) do
      empty!
      attribute(:name) { show! }
    end

    @c1.ar_serializable_hash(:rest, :view => v).should ==
     {
      :name => 'big_corp',
     }
  end

  it 'supports empty! on embedded resource' do
    v = ActiveRest::View.new(:show) do
      empty!
      attribute :location do
        show!
        empty!
      end
    end

    @c.ar_serializable_hash(:rest, :view => v).should ==
     {
      :location => { },
     }
  end

  it 'supports empty! on embedded collection' do
    v = ActiveRest::View.new(:show) do
      empty!
      attribute :phones do
        show!
        empty!
      end
    end

    @c.ar_serializable_hash(:rest, :view => v).should ==
     {
      :phones => [{  },
                  {  }],
     }
  end

  it 'allows inclusion of referenced resources' do
    v = ActiveRest::View.new(:show) do
      attribute(:group) { include! }
    end

    @c.ar_serializable_hash(:rest, :view => v).should include(
     {
      :group =>
       {
        :id => 1001,
        :name => 'MegaHolding',
        :_type => 'Group',
#        :_object_perms=>{:read=>true, :write=>true, :delete=>true},
#        :_attr_perms=> {
#          :id=>{:read=>true, :write=>true},
#          :name=>{:read=>true, :write=>true},
#          :companies=>{:read=>true, :write=>true}
#        }
       }
     })
  end

  it 'allows inclusion of referenced resources in empty! resources' do
    v = ActiveRest::View.new(:show) do
      empty!
      attribute(:group) { include! }
    end

    @c.ar_serializable_hash(:rest, :view => v).should ==
     {
      :group =>
       {
        :id => 1001, :name => 'MegaHolding',
        :_type=> 'Group',
#        :_object_perms => { :read => true, :write => true, :delete => true },
#        :_attr_perms => { :id => { :read => true, :write => true },
#                          :name => { :read => true, :write => true },
#                          :companies => { :read => true, :write => true }}
       }
     }
  end

  it 'suports empty! on included referenced resource' do
    v = ActiveRest::View.new(:show) do
      empty!
      attribute :group do
        include!
        empty!
      end
    end

    @c.ar_serializable_hash(:rest, :view => v).should ==
     {
      :group => {  },
     }
  end

  it 'suports explicit showing of attributes into included referenced resource' do
    v = ActiveRest::View.new(:show) do
      empty!
      attribute :group do
        include!
        empty!

        attribute :id do
          show!
        end
      end
    end

    @c.ar_serializable_hash(:rest, :view => v).should ==
     {
      :group => { :id => 1001 },
     }
  end

  it 'suports empty! on included referenced collection' do
    v = ActiveRest::View.new(:show) do
      empty!
      attribute :users do
        include!
        empty!
      end
    end

    @c.ar_serializable_hash(:rest, :view => v).should ==
     {
      :users => [{  }, {  }],
     }
  end

  it 'supports explicit showing of attribute on included referenced collection' do
    v = ActiveRest::View.new(:show) do
      empty!
      attribute :users do
        include!
        empty!

        attribute :id do
          show!
        end
      end
    end

    @c.ar_serializable_hash(:rest, :view => v).should ==
     {
      :users => [{ :id => 1001 },
                 { :id => 1002 }],
     }
  end

  describe View, 'virtual' do

    it 'adds a virtual attribute with static value' do
      v = ActiveRest::View.new(:show) do
        empty!
        attribute(:virtual_attribute) do
          virtual :string do
            'virtual_value'
          end
        end
      end

      @c1.ar_serializable_hash(:rest, :view => v).should ==
       {
        :virtual_attribute => 'virtual_value'
       }
    end

    it 'adds a virtual attribute with Proc value' do
      v = ActiveRest::View.new(:show) do
        empty!
        attribute(:virtual_attribute) do
          virtual :string do
            name.upcase
          end
        end
      end

      @c1.ar_serializable_hash(:rest, :view => v).should ==
       {
        :virtual_attribute => 'BIG_CORP'
       }
    end

    it 'adds a virtual attribute to an embedded resource' do

      v = ActiveRest::View.new(:show) do
        empty!
        attribute(:location) do
          show!
          empty!
          attribute :virtual_attribute do
            virtual :string do
              'virtual_value'
            end
          end
        end
      end

      @c.ar_serializable_hash(:rest, :view => v).should ==
       {
        :location => { :virtual_attribute => 'virtual_value' },
       }
    end

    it 'adds a virtual attribute to an included referenced resource' do

      v = ActiveRest::View.new(:show) do
        empty!
        attribute(:group) do
          include!
          empty!
          attribute :virtual_attribute do
            virtual :string do
              'virtual_value'
            end
          end
        end
      end

      @c.ar_serializable_hash(:rest, :view => v).should ==
       {
        :group => { :virtual_attribute => 'virtual_value' },
       }
    end

    it 'adds a virtual attribute to an embedded resource collection' do

      v = ActiveRest::View.new(:show) do
        empty!
        attribute(:phones) do
          show!
          empty!
          attribute :virtual_attribute do
            virtual :string do
              'virtual_value'
            end
          end
        end
      end

      @c.ar_serializable_hash(:rest, :view => v).should ==
       {
        :phones => [{ :virtual_attribute => 'virtual_value' },
                    { :virtual_attribute => 'virtual_value' }],
       }
    end

    it 'adds a virtual attribute to an included referenced resource collection' do

      v = ActiveRest::View.new(:show) do
        empty!
        attribute(:users) do
          include!
          empty!
          attribute :virtual_attribute do
            virtual :string do
              'virtual_value'
            end
          end
        end
      end

      @c.ar_serializable_hash(:rest, :view => v).should ==
       {
        :users => [{ :virtual_attribute => 'virtual_value' },
                   { :virtual_attribute => 'virtual_value' }],
       }
    end
  end
end

describe View, 'with_perms!' do
  before(:each) do
    @c = FactoryGirl.create(:company_complex)
  end

  it 'adds permissions to an empty resource' do
    v = ActiveRest::View.new(:show) do
      empty!
      with_perms!
    end

    @c.ar_serializable_hash(:rest, :view => v).should deep_include(
     {
      :_perms => {
        :attributes => { :id => 'RW' },
        :allowed_actions => [ ],
      }
     })
  end
end

#p:_type => 'CompanyLocation'

end
