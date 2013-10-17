class CompanyLocation < ActiveRecord::Base
  include ActiveRest::Model

  has_many :companies

  has_one :coordinate, :class_name => 'CompanyLocationCoordinate'

  interface :rest do
  end
end

class CompanyLocationCoordinate < ActiveRecord::Base
  include ActiveRest::Model

  belongs_to :company_location

  interface :rest do
  end
end
