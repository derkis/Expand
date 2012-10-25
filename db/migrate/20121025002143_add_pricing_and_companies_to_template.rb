class AddPricingAndCompaniesToTemplate < ActiveRecord::Migration
  def change
    add_column :templates, :pricing, :text

    add_column :templates, :companies, :text

  end
end
