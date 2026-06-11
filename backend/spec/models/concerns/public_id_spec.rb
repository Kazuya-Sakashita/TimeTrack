require "rails_helper"

RSpec.describe PublicId do
  describe ".generate" do
    it "prefix と区切りを含む文字列を返す" do
      id = described_class.generate(prefix: "usr")

      expect(id).to start_with("usr_")
      expect(id.length).to eq("usr_".length + PublicId::RANDOM_LENGTH)
    end

    it "英数字のランダム部を持つ" do
      id = described_class.generate(prefix: "att")
      random_part = id.delete_prefix("att_")

      expect(random_part).to match(/\A[A-Za-z0-9]+\z/)
    end

    it "呼び出しごとに異なる値を返す（衝突しにくい）" do
      ids = Array.new(1000) { described_class.generate(prefix: "usr") }

      expect(ids.uniq.size).to eq(1000)
    end

    it "prefix が空なら ArgumentError" do
      expect { described_class.generate(prefix: "") }.to raise_error(ArgumentError)
    end
  end
end
