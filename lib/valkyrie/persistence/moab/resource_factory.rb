# frozen_string_literal: true
module Valkyrie::Persistence::Moab
  class ResourceFactory
    attr_reader :adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    def from_resource(resource:)
      ModelConverter.new(resource: resource, adapter: adapter).convert
    end

    def to_resource(object:)
      #OrmConverter.new(object: object, adapter: adapter).convert
    end
  end
end