class Company < ActiveRecord::Base

  class FullAddress
    include ActiveRest::Model

    attr_reader :street, :city, :zip

    interface :rest do
      attribute(:street)
      attribute(:city)
      attribute(:zip)
    end

    def initialize(street, city, zip)
      @street = street
      @city = city
      @zip = zip
    end

    def to_s
      [ @street, @city, @zip ].compact.join(', ')
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
              [ :street, :street ],
              [ :city, :city ],
              [ :zip, :zip ],
            ]

  belongs_to :object_1, :polymorphic => true, :embedded => true
  belongs_to :object_2, :polymorphic => true, :embedded => true

  belongs_to :polyref_1, :polymorphic => true
  belongs_to :polyref_2, :polymorphic => true

  validates_presence_of :name
  validates_uniqueness_of :name

  interface :rest do
    attribute :name do
      self.human_name = 'Nome'
    end

    # Make a test to see if a virtual attribute can be create without block
    attribute :city

    attribute :phones do
      self.human_name = 'Phone numbers'
    end

    attribute :virtual, 'String' do
      self.human_name = 'Virtual Attribute'
    end

    attribute :excluded_attribute do
      exclude!
    end

    attribute :not_readable_attribute do
      not_readable!
    end

    attribute :not_writable_attribute do
      not_writable!
    end
  end

  interface :search_result do
    self.activerecord_autoinit = false
    attribute(:id) { self.type = :integer }
    attribute(:search_summary) { self.type = :string }
  end

  def search_summary
    'This is company summary'
  end

  def virtual
    'This is the virtual value'
  end

  def self.scope1
    where(:id => 1)
  end

  def self.scope_for_id_2
    where(:id => 2)
  end
end
