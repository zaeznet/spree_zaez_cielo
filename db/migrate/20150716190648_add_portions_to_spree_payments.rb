class AddPortionsToSpreePayments < ActiveRecord::Migration
  def change
    add_column :spree_payments, :portions, :integer
  end
end
