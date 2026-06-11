# public_id 用のマイグレーションヘルパ (add_public_id) をマイグレーションで使えるようにする。
require_relative "../../lib/public_id/migration"

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Migration.include(PublicIdMigration)
end
