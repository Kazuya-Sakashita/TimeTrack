class MeController < ApplicationController
  before_action :authenticate_request

  # GET /me
  def show
    render json: UserSerializer.call(current_user)
  end
end
