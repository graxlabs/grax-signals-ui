class ScoringRunsController < ApplicationController
  before_action :authenticate_user!

  def index
    @runs = ScoringRun.recent
    # .page(params[:page])
  end

  def show
    @run = ScoringRun.find(params[:id])
  end
end
