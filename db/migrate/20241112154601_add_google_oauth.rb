class AddGoogleOauth < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :full_name, :string
    add_column :users, :uid, :string
    add_column :users, :avatar_url, :string
    add_column :users, :provider, :string

    add_index :users, [:uid, :provider], unique: true
  end
end
