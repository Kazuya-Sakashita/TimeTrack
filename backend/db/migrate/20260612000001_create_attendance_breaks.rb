class CreateAttendanceBreaks < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_breaks do |t|
      add_public_id t # public_id (NOT NULL + 一意インデックス)

      t.references :attendance, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :ended_at # 休憩中は null

      t.timestamps
    end
  end
end
