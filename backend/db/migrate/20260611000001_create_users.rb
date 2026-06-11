class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      add_public_id t # public_id (NOT NULL + 一意インデックス)

      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      # role: 0=employee, 1=manager, 2=admin（enum）
      t.integer :role, null: false, default: 0

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
