
FactoryGirl.define do
  factory :account1, :class => 'Account' do
    id 1
    name 'Account1'
    balance 10
    secret 'Pippo'
  end

  factory :account2, :class => 'Account' do
    id 2
    name 'Account2'
    balance 20
    secret 'Pluto'
  end

  factory :account3, :class => 'Account' do
    id 3
    name 'Account3 Sfigato'
    balance -30
    secret 'Paperino'
  end


end
