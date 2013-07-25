
FactoryGirl.define do
  factory :account1, :class => 'Account' do
    name 'Account1'
    secret 'Pippo'
  end

  factory :account2, :class => 'Account' do
    name 'Account2'
    secret 'Pluto'
  end

  factory :account3, :class => 'Account' do
    name 'Account3'
    secret 'Paperino'
  end


end
