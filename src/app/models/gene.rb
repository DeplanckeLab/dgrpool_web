class Gene < ApplicationRecord


  searchable do
    text :name
    text :full_name
    text :identifier
    text :synonyms do
      (synonyms) ? synonyms.split("|") : nil
    end
    string :name_order do
      name
    end
  end
  
end
