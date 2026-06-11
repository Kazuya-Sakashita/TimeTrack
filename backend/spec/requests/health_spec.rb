require "rails_helper"

# Walking Skeleton の疎通を Request Spec で担保する（testing-policy.md）。
RSpec.describe "Health", type: :request do
  describe "GET /health" do
    it "returns 200 with status ok and db ok" do
      get "/health"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("ok")
      expect(body["db"]).to eq("ok")
    end
  end
end
