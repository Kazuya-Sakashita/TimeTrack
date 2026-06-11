# モデルに public_id を持たせる concern。
#   class User < ApplicationRecord
#     include HasPublicId
#     has_public_id_prefix "usr"
#   end
# - 作成時に public_id を自動採番
# - URL では public_id を使う（to_param）。内部 id を外部に出さない。
module HasPublicId
  extend ActiveSupport::Concern

  included do
    # presence バリデーションより先に採番するため before_validation を使う
    before_validation :assign_public_id, on: :create
    validates :public_id, presence: true, uniqueness: true
  end

  class_methods do
    def has_public_id_prefix(prefix)
      @public_id_prefix = prefix
    end

    def public_id_prefix
      @public_id_prefix || raise("has_public_id_prefix is not set for #{name}")
    end

    def generate_public_id
      PublicId.generate(prefix: public_id_prefix)
    end
  end

  # ルーティングで内部 id ではなく public_id を使う
  def to_param
    public_id
  end

  private

  def assign_public_id
    self.public_id ||= self.class.generate_public_id
  end
end
