class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :referral_code, null: false
      t.references :referred_by, null: true, foreign_key: { to_table: :users }
      t.integer :reward_count, default: 0, null: false
      t.integer :reward_status, default: 0, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :referral_code, unique: true
  end
end
