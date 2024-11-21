class LeadsController < ApplicationController
  def index
    subquery = LeadScoreSnapshot
      .select('DISTINCT ON (lead_id) lead_id, total_score, previous_score, calculated_at, dimension_scores')
      .order('lead_id, calculated_at DESC')

    @lead_snapshots = LeadScoreSnapshot
      .select('latest.*')
      .from("(#{subquery.to_sql}) latest")
      .order('total_score DESC')
      .page(params[:page])
      .per(50)
  end

  def show
    @lead_snapshots = LeadScoreSnapshot
      .where(lead_id: params[:id])
      .order(calculated_at: :desc)
      .page(params[:page])
      .per(10)

    @current_snapshot = @lead_snapshots.first
  end
end