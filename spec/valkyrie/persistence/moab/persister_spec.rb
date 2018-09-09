# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Valkyrie::Persistence::Moab::Persister do
  after(:all) do
    FileUtils.remove_dir(File.join(ROOT_PATH.join("tmp"), "files_test"), force: true)
  end

  let(:adapter) { Valkyrie::Persistence::Moab::MetadataAdapter.new(storage_roots: [ROOT_PATH.join("tmp")], storage_trunk: "files_test") }
  let(:query_service) { adapter.query_service }
  let(:persister) { adapter.persister }
  let(:resource_factory) { adapter.resource_factory }
  it_behaves_like "a Valkyrie::Persister"
end
