 #to_csv create a file for initial upload to socrata - creates a csv file containing all records in our DB
require 'rubygems'
require 'active_record'
require 'sqlite3'
require 'configatron'
require 'csv'
require_relative '../../lib/scf_logger.rb'
require_relative '../../lib/defaults.rb'



 DB=ActiveRecord::Base.establish_connection(
 :adapter  => 'sqlite3',
 :database => '../../db/seeCF.db'
)

class Issue < ActiveRecord::Base 
  
  def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.each do |issue|
        csv << issue.attributes.values_at(*column_names)
      end
    end
  end
 def issues_to
 @issues=Issue.all 
 @csv=@issues.to_csv
 File.open('see_cf.csv', 'w') { |file| file.write(@csv) }
 end

end

Issue.new.issues_to
