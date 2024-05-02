class Gene < ApplicationRecord


  searchable do
    text :name
    string :name_order do
      name
    end
  end
  
end
