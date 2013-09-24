class CreateAll < ActiveRecord::Migration
  def self.up
    create_table :companies, :force => true do |t|
      t.timestamps
      t.string   :name,       :null => false
      t.string   :city
      t.string   :street
      t.string   :zip
      t.boolean  :is_active
      t.timestamp :registration_date
      t.references :location
      t.references :group
      t.references :object_1, :polymorphic => true
      t.references :object_2, :polymorphic => true
      t.references :polyref_1, :polymorphic => true
      t.references :polyref_2, :polymorphic => true
      t.integer :excluded_attribute
      t.integer :not_readable_attribute
      t.integer :not_writable_attribute
    end

    create_table :company_bars, :force => true do |t|
      t.timestamps
      t.string   :name
    end

    create_table :company_foos, :force => true do |t|
      t.timestamps
      t.string   :name
    end

    create_table :company_phones, :force => true do |t|
      t.references :company
      t.string :number
    end

    create_table :company_locations, :force => true do |t|
      t.float :lat
      t.float :lon
      t.string :raw_name
    end

    create_table :groups, :force => true do |t|
      t.string :name
    end

    create_table :contacts, :force => true do |t|
      t.timestamps
      t.references :owner, :polymorphic => true
      t.string   :field
      t.string   :value
    end

    create_table :users, :force => true do |t|
      t.timestamps
      t.string   :name
      t.references  :company
    end

    create_table :external_object_bars, :force => true do |t|
      t.string   :name
    end

    create_table :external_object_foos, :force => true do |t|
      t.string   :name
    end

    create_table :ownable_object_bars, :force => true do |t|
      t.string   :name
      t.references :owner
    end

    create_table :ownable_object_foos, :force => true do |t|
      t.string   :name
      t.references  :owner
    end

    create_table :accounts, :force => true do |t|
      t.string   :name
      t.string   :secret
      t.integer  :balance
    end


  end

  def self.down
  end
end
