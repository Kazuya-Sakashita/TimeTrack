# Be sure to restart your server when you modify this file.
#
# フロントエンド（Next.js）からのクロスオリジン要求を許可する。
# 許可オリジンは環境変数で明示し、ワイルドカードは使わない（security-policy.md）。
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONTEND_ORIGIN", "http://localhost:3001")

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization]
  end
end
