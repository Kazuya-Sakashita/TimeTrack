# アプリ + DB の疎通を確認するヘルスチェック。
# Walking Skeleton（frontend → backend → db）の背骨として使う。
class HealthController < ApplicationController
  def show
    render json: { status: "ok", db: database_status }
  end

  private

  def database_status
    ActiveRecord::Base.connection.execute("SELECT 1")
    "ok"
  rescue StandardError
    "error"
  end
end
