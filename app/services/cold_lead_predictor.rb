class ColdLeadPredictor
  MODEL_PATH = Rails.root.join('ml-models', 'cold-leads-1.pkl')

  def self.predict(lead_attributes)
    new.predict(lead_attributes)
  end

  def predict(lead_attributes)
    command = [
      Rails.root.join('bin', 'inference-cold-leads.py').to_s,
      lead_attributes.to_json
    ]

    output = IO.popen(command, err: [:child, :out]) { |io| io.read }

    puts "AM I HERE?"
    $stdout.puts "OUTPUT: #{output.inspect}"
    $stdout.flush()

    result = JSON.parse(output)


    if result['success']
      {
        prediction: result['prediction'],
        probability: result['probability'],
        score: result['score']
      }
    else
      raise "Prediction failed: #{result['error']}"
    end
  end
end