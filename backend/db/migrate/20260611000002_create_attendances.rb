class CreateAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendances do |t|
      add_public_id t # public_id (NOT NULL + 一意インデックス)

      t.references :user, null: false, foreign_key: true
      t.date :work_date, null: false
      t.datetime :clock_in_at, null: false
      t.datetime :clock_out_at
      # status: 0=working, 1=finished
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    # 1人1日1レコード（二重出勤を防ぐ）
    add_index :attendances, [ :user_id, :work_date ], unique: true
  end
end
