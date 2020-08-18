require "readme/har_collection"
require "readme/filter"

RSpec.describe Readme::HarCollection do
  describe "#to_h" do
    it "returns a hash with filtering applied" do
      hash = {keep: "keep", reject: "reject"}
      filter = double(filter: {keep: "kept"})
      collection = Readme::HarCollection.new(filter, hash)

      expect(collection.to_h).to eq({keep: "kept"})
    end
  end

  describe "#to_a" do
    it "returns an array with filtering applied" do
      hash = {keep: "keep", reject: "reject"}
      filter = double(filter: {keep: "kept"})
      collection = Readme::HarCollection.new(filter, hash)

      expect(collection.to_a).to eq([{name: :keep, value: "kept"}])
    end
  end
end