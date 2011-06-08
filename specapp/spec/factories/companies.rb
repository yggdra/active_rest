
FactoryGirl.define do
  factory :company_1, :class => 'Company' do
  #  x.association :person, :factory => :person_test
    id 1
    name 'big_corp'
    city 'NY'
    street 'Fifth Avenue'
    zip '28021'
    is_active true
    registration_date '2001-01-01'
  end

  factory :company_2, :class => 'Company' do
    id 2
    name 'compuglobal'
    city 'Springfield'
    street 'Bart\'s road'
    zip '513'
    is_active false
    registration_date '2012-12-13'
  end

  factory :company_3, :class => 'Company' do
    id 3
    name 'newerOS'
    city 'Springfield'
    street 'Hill road, 3'
    zip '01001'
    is_active true
    registration_date '1900-01-01'
  end

  factory :group, :class => 'Group' do
    name 'MegaHolding'
  end

  factory :company_location, :class => 'CompanyLocation' do
    lat 0.12345
    lon 9.12345
    raw_name 'Seveso'
  end

  factory :company_phone, :class => 'Company::Phone' do
    number '99999999'
  end

  factory :company_foo, :class => 'Company::Foo' do
  end

  factory :company_bar, :class => 'Company::Bar' do
  end

  factory :ext_obj_foo, :class => 'ExternalObjectFoo' do
  end

  factory :ext_obj_bar, :class => 'ExternalObjectBar' do
  end

  factory :user, :class => 'User' do
  end

  factory :company_complex, :class => 'Company' do
    id 4
    name 'Huge Corp Corp.'
    city 'Seveso'
    street 'Via Mezzera 29/A'
    zip '20030'
    is_active true

    users { [association(:user, :name => 'Paolino Paperino'),
             association(:user, :name => 'Zio Paperone')] }

    association :location, :factory => :company_location
    phones { [association(:company_phone, :number => 99999999),
              association(:company_phone, :number => 12345678)] }

    association :group, :factory => :group

    association :object_1, :factory => :company_foo
    association :object_2, :factory => :company_bar

    association :polyref_1, :factory => :ext_obj_foo
    association :polyref_2, :factory => :ext_obj_bar
  end

end
