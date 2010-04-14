
Factory.define :company_1, :class => 'Company' do |x|
#  x.association :person, :factory => :person_test
  x.id 1
  x.name 'big_corp'
  x.city 'NY'
  x.street 'Fifth Avenue'
  x.zip '28021'
  x.is_active true
end

Factory.define :company_2, :class => 'Company' do |x|
  x.id 2
  x.name 'compuglobal'
  x.city 'Springfield'
  x.street 'Bart\'s road'
  x.zip '513'
  x.is_active false
end

Factory.define :company_3, :class => 'Company' do |x|
  x.id 3
  x.name 'newerOS'
  x.city 'Springfield'
  x.street 'Hill road, 3'
  x.zip '01001'
  x.is_active true
end
