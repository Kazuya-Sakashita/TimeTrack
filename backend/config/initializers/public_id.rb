# public_id 用のマイグレーションヘルパ (add_public_id) をマイグレーションで使えるようにする。
# PublicIdMigration は lib/public_id_migration.rb から Zeitwerk が autoload する。
ActiveSupport.on_load(:active_record) do
  ActiveRecord::Migration.include(PublicIdMigration)
end
