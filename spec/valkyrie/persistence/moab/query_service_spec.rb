# frozen_string_literal: true
require "spec_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe Valkyrie::Persistence::Moab::QueryService do
  let(:adapter) do
    Valkyrie::Persistence::Moab::MetadataAdapter.new(
      storage_roots: [ROOT_PATH.join("tmp").to_s],
      storage_trunk: "files_test"
    )
  end

  let(:query_service) { adapter.query_service }
  let(:persister) { adapter.persister }
  after do
    persister.wipe!
  end
  it_behaves_like "a Valkyrie query provider"
end
