module ScoringRunsHelper
  def status_badge_class(status)
    case status
    when 'completed'
      'bg-success'
    when 'running'
      'bg-primary'
    when 'pending'
      'bg-warning'
    when 'failed'
      'bg-danger'
    else
      'bg-secondary'
    end
  end
end