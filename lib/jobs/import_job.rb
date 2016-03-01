require 'csv'

class ImportJob

  attr_reader :directory

  def initialize(directory = 'db/import')
    @directory = directory.split('/')
  end

  def perform!
    ActiveRecord::Base.transaction do
      $logger.info '----> Loading Applicants'
      load_applicants
      $logger.info '----> Loading Positions'
      load_positions
      $logger.info '----> DONE'
    end
  end

  private

  def load_applicants
    file = assert_file('applicants.csv')
    CSV.foreach(file, headers: true) do |row|
      location = factory.point(row[0], row[1])
      params = {
        interests: [row[3], row[4], row[5]],
        prefers_nearby:   row[6],
        has_transit_pass: row[7],
        location: location
      }
      Applicant.create! params
    end
  end

  def load_positions
    file = assert_file 'positions.csv'
    CSV.foreach(file, headers: true) do |row|
      params = { category: row[1], location: factory.point(row[2], row[3]) }
      Position.create! params
    end
  end

  def factory
    RGeo::Geographic.spherical_factory srid: 4326
  end

  def default_dir
    File.join Dir.pwd, 'db', 'import'
  end

  def assert_file(filename)
    file = File.join(@directory, filename)
    raise ArgumentError, "File does not exist: #{file}" unless File.exists?(file)
    file
  end
end
