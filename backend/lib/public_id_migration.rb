# マイグレーションで public_id カラムを一貫した形で追加するヘルパ。
#   class CreateUsers < ActiveRecord::Migration[8.1]
#     def change
#       create_table :users do |t|
#         add_public_id t
#         ...
#       end
#     end
#   end
# public_id は NOT NULL + 一意インデックス（database-policy.md）。
#
# NOTE: 生成ロジックの PublicId（app/models/concerns/public_id.rb）と
# 定数衝突しないよう PublicIdMigration とし、Zeitwerk の命名規則に合わせて
# ファイル名も public_id_migration.rb にしている。
module PublicIdMigration
  # create_table のブロック内（t）でも、テーブル名指定でも使える
  def add_public_id(table_or_definition)
    if table_or_definition.respond_to?(:string)
      # create_table のテーブル定義オブジェクト
      table_or_definition.string :public_id, null: false
      table_or_definition.index :public_id, unique: true
    else
      # 既存テーブルへの追加
      add_column table_or_definition, :public_id, :string, null: false
      add_index table_or_definition, :public_id, unique: true
    end
  end
end
