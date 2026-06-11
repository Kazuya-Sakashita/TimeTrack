class CreateAttendanceChangeRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_change_requests do |t|
      add_public_id t # public_id (NOT NULL + 一意インデックス)

      t.references :user, null: false, foreign_key: true        # 申請者
      t.references :attendance, null: false, foreign_key: true   # 対象勤怠
      t.references :reviewer, foreign_key: { to_table: :users }  # 承認者（任意）

      t.datetime :proposed_clock_in_at
      t.datetime :proposed_clock_out_at
      t.text :reason, null: false
      # status: 0=pending, 1=approved, 2=rejected
      t.integer :status, null: false, default: 0
      t.datetime :reviewed_at
      t.text :review_comment

      t.timestamps
    end
  end
end
