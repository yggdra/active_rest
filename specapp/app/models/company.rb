class Company < ActiveRecord::Base

  class FullAddress
    attr_reader :address, :city, :zip

    def initialize(address, city, zip)
      @address = address
      @city = city
      @zip = zip
    end

    def export_as_hash(opts = {})
      { :address => @address, :city => @city, :zip => @zip }
    end

    def to_s
      [ @address, @city, @zip ].compact.join(', ')
    end
  end

  class Phone < ActiveRecord::Base
    include ActiveRest::Model
    belongs_to :company

    interface :rest do
    end
  end

  class Foo < ActiveRecord::Base
    include ActiveRest::Model

    interface :rest do
    end
  end

  class Bar < ActiveRecord::Base
    include ActiveRest::Model

    interface :rest do
    end
  end


  include ActiveRest::Model

  has_many :users
  has_many :contacts, :as => :owner

  belongs_to :group,
             :class_name => 'Group'

  has_many :phones,
           :class_name => 'Company::Phone',
           :embedded => true

  belongs_to :location,
             :class_name => 'CompanyLocation',
             :embedded => true

  composed_of :full_address,
            :class_name => '::Company::FullAddress',
            :mapping => [
              [ :address, :address ],
              [ :city, :city ],
              [ :city, :zip ],
            ]

  belongs_to :object_1, :polymorphic => true, :embedded => true
  belongs_to :object_2, :polymorphic => true, :embedded => true

  belongs_to :polyref_1, :polymorphic => true
  belongs_to :polyref_2, :polymorphic => true

  validates_presence_of :name
  validates_uniqueness_of :name

  interface :rest do
    attribute :name do
      human_name 'Nome'
    end

    attribute :phones do
      human_name 'Phone numbers'
    end

    attribute :virtual do
      human_name 'Virtual Attribute'
      type :string
    end
  end

  def virtual
    'This is the virtual value'
  end
end
