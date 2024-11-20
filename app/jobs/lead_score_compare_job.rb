class LeadScoreCompareJob < ApplicationJob
  def perform
    query1 = File.read(Rails.root.join('lib', 'queries', 'lead_score2.sql'))
    query2 = Scoring::LeadScoringService.build_query

    athena = AthenaQuery.new
    results1 = athena.execute_query(query1)
    results2 = athena.execute_query(query2)

    puts "Results1: #{results1.size}"
    puts "Results2: #{results2.size}"

    results1[1..].each_with_index do |row, index|
      row2 = results2[index+1]
      if row[0] != row2[0] || row[1] != row2[1] || row[2] != row2[2]
        puts "Mismatched"
        puts "Row1: #{row}"
        puts "Row2: #{row2}"
      else
        print "."
      end
    end
  end
end