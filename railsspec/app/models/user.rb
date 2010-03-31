class User < ActiveRecord::Base
  belongs_to :company
  has_many :contacts,:as => :owner
end
