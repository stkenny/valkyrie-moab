# frozen_string_literal: true
module Valkyrie::Persistence::Moab
  class ModelConverter
    include Valkyrie::Moab

    attr_reader :resource

    def initialize(resource:)
      @resource = resource
    end

    def convert
      metadata_file = Tempfile.new("#{resource.id}_jsonld")
      begin
        File.open(metadata_file, "w") do |f|
          f.write(resource_metadata(resource).to_json)
        end

        add_to_moab(resource.id.to_s, 'metadata', metadata_file, "#{resource.id}.jsonld")
      ensure
        metadata_file.close
        metadata_file.unlink # deletes the temp file
      end

      resource
    end

    private

      def resource_metadata(resource)
        output = resource.to_h.except(:imported_metadata).compact
        if output[:optimistic_lock_token]
          output[:optimistic_lock_token] = Array.wrap(output[:optimistic_lock_token]).map(&:serialize)
        end
        output
      end
  end
end
