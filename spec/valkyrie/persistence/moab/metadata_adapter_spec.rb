# frozen_string_literal: true
require "spec_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe Valkyrie::Persistence::Moab::MetadataAdapter do
  let(:adapter) do
    described_class.new(
      storage_roots: [ROOT_PATH.join("tmp").to_s],
      storage_trunk: "files_test"
    )
  end
  it_behaves_like "a Valkyrie::MetadataAdapter"
end
