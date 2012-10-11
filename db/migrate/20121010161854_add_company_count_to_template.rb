class AddCompanyCountToTemplate < ActiveRecord::Migration
  def change
    add_column :templates, :company_count, :integer

  end
end
