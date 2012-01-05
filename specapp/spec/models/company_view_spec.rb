require 'spec_helper'

module ActiveRest

describe View do

  before(:each) do
    @c1 = Factory(:company_1)
  end

  it 'by default outputs the whole object' do

    v = ActiveRest::View.new(:show) do
    end

    v.process(@c1).should ==
     {
      :id => 1,
      :created_at => @c1.created_at,
      :updated_at => @c1.updated_at,
      :name => 'big_corp',
      :city => 'NY',
      :street => 'Fifth Avenue',
      :zip => '28021',
      :is_active => true,
      :registration_date => @c1.registration_date,
      :group_id => nil,
      :object_1_id => nil,
      :object_1_type => nil,
      :object_2_id => nil,
      :object_2_type => nil,
      :polyref_1_id => nil,
      :polyref_1_type => nil,
      :polyref_2_id => nil,
      :polyref_2_type => nil,
      :phones => [],
      :location => nil,
      :full_address => { :address => nil, :city => 'NY', :zip => 'NY' },
      :object_1 => nil,
      :object_2 => nil,
      :virtual => 'This is the virtual value',
      :_type => 'Company',
      :_object_perms => { :read => true, :write => true, :delete => true },
      :_attr_perms =>
       {
        :id => {:read => true, :write => true},
        :created_at => {:read => true, :write => true},
        :updated_at => {:read => true, :write => true},
        :name => {:read => true, :write => true},
        :city => {:read => true, :write => true},
        :street => {:read => true, :write => true},
        :zip => {:read => true, :write => true},
        :is_active => {:read => true, :write => true},
        :registration_date => {:read => true, :write => true},
        :group_id => {:read => true, :write => true},
        :object_1_id => {:read => true, :write => true},
        :object_1_type => {:read => true, :write => true},
        :object_2_id => {:read => true, :write => true},
        :object_2_type => {:read => true, :write => true},
        :polyref_1_id => {:read => true, :write => true},
        :polyref_1_type => {:read => true, :write => true},
        :polyref_2_id => {:read => true, :write => true},
        :polyref_2_type => {:read => true, :write => true},
        :users => {:read => true, :write => true},
        :contacts => {:read => true, :write => true},
        :group => {:read => true, :write => true},
        :phones => {:read => true, :write => true},
        :location => {:read => true, :write => true},
        :full_address => {:read => true, :write => true},
        :object_1 => {:read => true, :write => true},
        :object_2 => {:read => true, :write => true},
        :polyref_1 => {:read => true, :write => true},
        :polyref_2 => {:read => true, :write => true},
        :owned_objects => {:read => true, :write => true},
        :virtual => {:read => true, :write => true}
       }
     }
  end

end


describe View, 'empty!' do

  before(:each) do
    @c1 = Factory(:company_1)
  end

  it 'removes all attributes' do

    v = ActiveRest::View.new(:show) do
      empty!
    end

    v.process(@c1).should ==
     {
     }
  end

end

describe View, 'attribute' do
  before(:each) do
    @c1 = Factory(:company_1)
    @c = Factory(:company_complex)
  end

  it 'allows showing of hidden attributes' do
    v = ActiveRest::View.new(:show) do
      empty!
      attribute(:name) { show! }
    end

    v.process(@c1).should ==
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

    v.process(@c).should ==
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

    v.process(@c).should ==
     {
      :phones => [{  },
                  {  }],
     }
  end

  it 'allows inclusion of referenced resources' do
    v = ActiveRest::View.new(:show) do
      attribute(:group) { include! }
    end

    v.process(@c).should include(
     {
      :group =>
       {
        :id=>1,
        :name=>"MegaHolding",
        :_type=>"Group",
        :_object_perms=>{:read=>true, :write=>true, :delete=>true},
        :_attr_perms=>
         {:id=>{:read=>true, :write=>true},
          :name=>{:read=>true, :write=>true},
          :companies=>{:read=>true, :write=>true}}

       }
     })
  end

  it 'allows inclusion of referenced resources in empty! resources' do
    v = ActiveRest::View.new(:show) do
      empty!
      attribute(:group) { include! }
    end

    v.process(@c).should ==
     {
      :group =>
       {
        :id => 1, :name => 'MegaHolding',
        :_type=> 'Group',
        :_object_perms => { :read => true, :write => true, :delete => true },
        :_attr_perms => { :id => { :read => true, :write => true },
                          :name => { :read => true, :write => true },
                          :companies => { :read => true, :write => true }}
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

    v.process(@c).should ==
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

    v.process(@c).should ==
     {
      :group => { :id => 1 },
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

    v.process(@c).should ==
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

    v.process(@c).should ==
     {
      :users => [{ :id => 1 },
                 { :id => 2 }],
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

      v.process(@c1).should ==
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

      v.process(@c1).should ==
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

      v.process(@c).should ==
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

      v.process(@c).should ==
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

      v.process(@c).should ==
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

      v.process(@c).should ==
       {
        :users => [{ :virtual_attribute => 'virtual_value' },
                   { :virtual_attribute => 'virtual_value' }],
       }
    end
  end
end

describe View, 'with_perms!' do
  before(:each) do
    @c = Factory(:company_complex)
  end

  it 'adds permissions to an empty resource' do

    v = ActiveRest::View.new(:show) do
      empty!
      with_perms!
    end

    v.process(@c).should ==
     {
      :_object_perms => { :read => true, :write => true, :delete => true},
      :_attr_perms => {}
     }
  end
end

#p:_type => 'CompanyLocation'

end
