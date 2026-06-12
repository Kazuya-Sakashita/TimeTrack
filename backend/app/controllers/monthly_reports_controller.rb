class MonthlyReportsController < ApplicationController
  before_action :authenticate_request

  # GET /monthly_reports/:month  (:month = YYYY-MM)
  def show
    parsed = MonthlyReport.parse_month(params[:month])
    return render_error("invalid_month", "月の形式は YYYY-MM です") if parsed.nil?

    year, month = parsed
    report = MonthlyReport.new(user: current_user, year:, month:)
    render json: MonthlyReportSerializer.call(report, month_param: params[:month])
  end
end
