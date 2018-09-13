# frozen_string_literal: true
module Valkyrie::Persistence::Moab
  class ResourceFactory

    def from_resource(resource:)
      Valkyrie::Persistence::Moab::ModelConverter.new(resource: resource).convert
    end

    def to_resource(object:)
      Valkyrie::Persistence::Moab::ORMConverter.new(object: object).convert
    end
  end
end
