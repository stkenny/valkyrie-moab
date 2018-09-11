# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Valkyrie::Persistence::Moab::Persister do
  after(:all) do
    FileUtils.remove_dir(File.join(ROOT_PATH.join("tmp").to_s, "files_test"), force: true)
  end

  let(:adapter) do
   Valkyrie::Persistence::Moab::MetadataAdapter.new(
     storage_roots: [ROOT_PATH.join("tmp").to_s],
     storage_trunk: "files_test")
  end
  let(:query_service) { adapter.query_service }
  let(:persister) { adapter.persister }
  it_behaves_like "a Valkyrie::Persister"
end
