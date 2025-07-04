# frozen_string_literal: true

# This class is used to import Google's Records.json file
# via the UI, vs the CLI, which uses the `GoogleMaps::RecordsImporter` class.

class GoogleMaps::RecordsStorageImporter
  BATCH_SIZE = 1000

  def initialize(import, user_id)
    @import = import
    @user = User.find_by(id: user_id)
  end

  def call
    process_file_in_batches
  rescue Oj::ParseError, JSON::ParserError => e
    Rails.logger.error("JSON parsing error: #{e.message}")
    raise
  end

  private

  attr_reader :import, :user

  def process_file_in_batches
    file_content = Imports::SecureFileDownloader.new(import.file).download_with_verification
    locations = parse_file(file_content)
    process_locations_in_batches(locations) if locations.present?
  end

  def parse_file(file_content)
    parsed_file = Oj.load(file_content, mode: :compat)
    return nil unless parsed_file.is_a?(Hash) && parsed_file['locations']

    parsed_file['locations']
  end

  def process_locations_in_batches(locations)
    batch = []
    index = 0

    locations.each do |location|
      batch << location

      next unless batch.size >= BATCH_SIZE

      process_batch(batch, index)
      index += BATCH_SIZE
      batch = []
    end

    # Process any remaining records that didn't make a full batch
    process_batch(batch, index) unless batch.empty?
  end

  def process_batch(batch, index)
    GoogleMaps::RecordsImporter.new(import, index).call(batch)
  end
end
