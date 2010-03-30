ActiveRecord::Schema.define(:version => 1) do

  create_table :active_rest_companies, :force => true do |t|
    t.column :name, :string
    t.column :city, :string
    t.column :street, :string
    t.column :zip, :string
  end

  create_table :active_rest_users, :force => true  do |t|
    t.references :company
    t.column :name, :string
  end

  create_table :active_rest_contacts, :force => true  do |t|
    t.references :owner, :polymorphic => true
    t.column :field, :string
    t.column :value, :string
  end

end
