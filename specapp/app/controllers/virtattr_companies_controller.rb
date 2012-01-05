class VirtattrCompaniesController < ApplicationController
  include ActiveRest::Controller

  layout false
  rest_controller_for Company

  view :show do
    # Simple virtual attribute
    attribute :upcase_name do
      virtual :string do |obj|
        obj.name.upcase
      end
    end

    # Collection attributes
    attribute :phones do
      attribute :dashed_number do
        virtual :string do |obj|
          obj.number.split('').join('-')
        end
      end
    end

    # Structured virtual attribute
    attribute :location do
      attribute :elevation do
        virtual :string do |obj|
          100
        end
      end
    end
  end

end
