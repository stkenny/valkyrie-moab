# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe Valkyrie::Storage::Moab do
  before do
    class TestResource < Valkyrie::Resource
    end
  end
  after do
    Object.send(:remove_const, :TestResource)
  end

  after(:all) do
    FileUtils.remove_dir(File.join(ROOT_PATH.join("tmp"), "moab"), force: true)
  end
  it_behaves_like "a Valkyrie::StorageAdapter"
  let(:storage_adapter) { described_class.new(storage_roots: [ROOT_PATH.join("tmp")], storage_trunk: "moab") }
  let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
  it "creates moab manifests on upload and deletes entries on delete" do
    output_file = storage_adapter.upload(file: file, original_filename: "example.tif", resource: TestResource.new(id: 'test'))
    storage_object = Moab::StorageObject.new('test', File.join(ROOT_PATH.join("tmp", "moab/te/st/test")))
    file_inventory = storage_object.current_version.file_inventory('version')
    expect(file_inventory.group_empty?('content')).to be false

    file_signature = storage_object.current_version.find_signature('content', 'example.tif')
    expect(file_signature.sha256).to eq "083faf236c9c79ab24ebc61fa60a02e5d2bfc9cc8a0944dac57ce2b6765deff3"
    expect(file_signature.sha1).to eq "8f86eeedf2d3833694325b4ca2a0aa70a3e080b4"
    expect(file_signature.md5).to eq "4174f0b23dba53e252ec0385cf2a2db9"

    storage_adapter.delete(id: output_file.id)
    storage_object = Moab::StorageObject.new('test', File.join(ROOT_PATH.join("tmp", "moab/te/st/test")))
    file_inventory = storage_object.current_version.file_inventory('version')
    expect(file_inventory.group_empty?('content')).to be true
  end
end
