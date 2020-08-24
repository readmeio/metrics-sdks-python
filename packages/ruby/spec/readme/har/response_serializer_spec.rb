require "readme/har/response_serializer"
require "readme/filter"

RSpec.describe Readme::Har::ResponseSerializer do
  describe "#as_json" do
    it "creates a structure that is valid according the schema" do
      request = build_request
      response = build_response

      serializer = Readme::Har::ResponseSerializer.new(request, response, Filter.for)
      json = serializer.as_json

      expect(json).to match_json_schema("response")
    end

    it "serializes values from the response, filtering cookies and headers" do
      request = build_request(cookies: {"cookie1" => "value1", "reject" => "reject"})
      response = build_response(
        status: 200,
        headers: {"X-Custom" => "custom", "reject" => "reject"},
        location: nil,
        body: StringIO.new("OK")
      )

      serializer = Readme::Har::ResponseSerializer.new(
        request,
        response,
        Filter.for(reject: ["reject"])
      )
      json = serializer.as_json

      expect(json[:status]).to eq 200
      expect(json[:statusText]).to eq "OK"
      expect(json[:httpVersion]).to eq request.http_version
      expect(json[:headers]).to match_array(
        [
          {name: "X-Custom", value: "custom"}
        ]
      )
      expect(json[:headersSize]).to eq(-1)
      expect(json[:bodySize]).to eq response.content_length
      expect(json[:redirectURL]).to eq ""
      expect(json[:cookies]).to match_array(
        [
          {name: "cookie1", value: "value1"}
        ]
      )
      expect(json.dig(:content, :text)).to eq "OK"
      expect(json.dig(:content, :size)).to eq response.content_length
      expect(json.dig(:content, :mimeType)).to eq response.content_type
    end

    it "filters JSON bodies" do
      request = build_request
      response = build_response(
        content_type: "application/json",
        body: StringIO.new({reject: "reject", keep: "keep"}.to_json)
      )

      serializer = Readme::Har::ResponseSerializer.new(
        request,
        response,
        Filter.for(reject: ["reject"])
      )
      json = serializer.as_json

      expect(json.dig(:content, :text)).to eq({keep: "keep"}.to_json)
      expect(json.dig(:content, :size)).to eq response.content_length
      expect(json.dig(:content, :mimeType)).to eq "application/json"
    end

    it "passes-through the raw body invalid JSON payloads" do
      request = build_request
      response = build_response(
        content_type: "application/json",
        body: StringIO.new("NOT JSON")
      )

      serializer = Readme::Har::ResponseSerializer.new(
        request,
        response,
        Filter.for
      )
      json = serializer.as_json

      expect(json.dig(:content, :text)).to eq "NOT JSON"
      expect(json.dig(:content, :size)).to eq response.content_length
      expect(json.dig(:content, :mimeType)).to eq "application/json"
    end

    it "handles responses without a body" do
      request = build_request
      response = build_response(status: 204, content_type: nil, body: nil)

      serializer = Readme::Har::ResponseSerializer.new(
        request,
        response,
        Filter.for(reject: ["reject"])
      )
      json = serializer.as_json

      expect(json[:content]).not_to have_key(:text)
      expect(json.dig(:content, :size)).to eq 0
      expect(json.dig(:content, :mimeType)).to eq ""
    end

    it "handles multiple JSON mime types" do
      json_mime_types = [
        "application/json",
        "application/x-json",
        "text/json",
        "text/x-json",
        "+json"
      ]
      request = build_request
      body = [{result: "value"}.to_json]

      json_mime_types.each do |mime_type|
        response = build_response(
          status: 200,
          content_type: mime_type,
          body: body
        )
        serializer = Readme::Har::ResponseSerializer.new(
          request,
          response,
          Filter.for
        )
        json = serializer.as_json

        expect(json[:content][:text]).to eq body.first
        expect(json[:content][:mimeType]).to eq mime_type
      end
    end
  end

  def build_request(overrides = {})
    defaults = {
      http_version: "HTTP/1.1",
      cookies: {"default_cookie" => "default"}
    }
    double(:request, defaults.merge(overrides))
  end

  def build_response(overrides = {})
    defaults = {
      status: 200,
      headers: {"X-Default" => "default"},
      content_type: "text/plain",
      content_length: 2,
      location: nil,
      body: StringIO.new("OK")
    }

    double(:response, defaults.merge(overrides))
  end
end