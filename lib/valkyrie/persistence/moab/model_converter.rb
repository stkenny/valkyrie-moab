# frozen_string_literal: true
module Valkyrie::Persistence::Moab
class ModelConverter
    attr_reader :resource, :adapter
    #delegate :base_path, to: :adapter
    def initialize(resource:, adapter:)
      @resource = resource
      @adapter = adapter
    end

    def convert
      []
    end
  end
end