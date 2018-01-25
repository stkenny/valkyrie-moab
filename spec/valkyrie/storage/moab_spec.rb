# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe Valkyrie::Storage::Moab do
  after(:all) do
    FileUtils.remove_dir(File.join(ROOT_PATH.join("tmp"), "files_test"), force: true)
  end
  it_behaves_like "a Valkyrie::StorageAdapter"
  let(:storage_adapter) { described_class.new(storage_roots: [ROOT_PATH.join("tmp")], storage_trunk: "files_test") }
  let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
end
