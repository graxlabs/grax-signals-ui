class LeadScoreCompareJob < ApplicationJob
  def perform
    query1 = File.read(Rails.root.join('lib', 'queries', 'lead_score2.sql'))
    query2 = Scoring::LeadScoringService.build_query

    athena = AthenaQuery.new
    results1 = athena.execute_query(query1)
    results2 = athena.execute_query(query2)

    puts "Results1: #{results1.size}"
    puts "Results2: #{results2.size}"

    results1_hash = {}

    results1[1..].each do |row|
      id = row[0]
      current_score = row[1]
      new_score = row[2]
      results1_hash[id] = { current_score: current_score, new_score: new_score }
    end

    results2[1..].each do |row|
      id = row[0]
      current_score = row[1]
      new_score = row[2]
      match = results1_hash[id]

      if match
        if match[:current_score] != current_score || match[:new_score] != new_score
          puts "Lead #{id} has different scores"
          puts "  Current: #{match[:current_score]} vs #{current_score}"
          puts "  New: #{match[:new_score]} vs #{new_score}"
        end
      else
        puts "Lead #{id} not found in first query"
      end
      print "."
      $stdout.flush
    end

    puts "\nComparison complete"
  end
end