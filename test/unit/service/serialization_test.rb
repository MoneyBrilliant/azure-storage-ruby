#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# The MIT License(MIT)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files(the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions :

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#--------------------------------------------------------------------------
require "unit/test_helper"
require "azure/storage/common"

describe Azure::Storage::Common::Service::Serialization do
  subject { Azure::Storage::Common::Service::Serialization }

  let(:storage_service_properties) { Azure::Storage::Common::Service::StorageServiceProperties.new }
  let(:storage_service_properties_xml) { Fixtures["storage_service_properties"] }

  describe "#signed_identifiers_from_xml" do
    let(:signed_identifiers_xml) { Fixtures["container_acl"] }

    it "accepts an XML string" do
      subject.signed_identifiers_from_xml signed_identifiers_xml
    end

    it "returns an Array of SignedIdentifier instances" do
      results = subject.signed_identifiers_from_xml signed_identifiers_xml
      _(results).must_be_kind_of Array
      _(results[0]).must_be_kind_of Azure::Storage::Common::Service::SignedIdentifier
      _(results.count).must_equal 1
    end
  end

  describe "#signed_identifiers_to_xml" do
    let(:signed_identifiers) {
      identifier = Azure::Storage::Common::Service::SignedIdentifier.new
      identifier.id = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
      identifier.access_policy.start = "2009-09-28T08:49:37.0000000Z"
      identifier.access_policy.expiry = "2009-09-29T08:49:37.0000000Z"
      identifier.access_policy.permission = "rwd"
      [identifier]
    }

    let(:signed_identifiers_xml) { Fixtures["container_acl"] }

    it "accepts a list of SignedIdentifier instances" do
      subject.signed_identifiers_to_xml signed_identifiers
    end

    it "returns a XML graph of the provided values" do
      xml = subject.signed_identifiers_to_xml signed_identifiers
      _(xml).must_equal signed_identifiers_xml
    end
  end

  describe "#signed_identifier_from_xml" do
    let(:signed_identifier_xml) { Nokogiri.Slop(Fixtures["container_acl"]).root.SignedIdentifier }
    let(:mock_access_policy) { mock }
    before { subject.expects(:access_policy_from_xml).with(signed_identifier_xml.AccessPolicy).returns(mock_access_policy) }

    it "accepts an XML node" do
      subject.signed_identifier_from_xml signed_identifier_xml
    end

    it "returns a SignedIdentifier instance" do
      identifier = subject.signed_identifier_from_xml signed_identifier_xml
      _(identifier).must_be_kind_of Azure::Storage::Common::Service::SignedIdentifier
    end

    it "sets the properties of the SignedIdentifier" do
      identifier = subject.signed_identifier_from_xml signed_identifier_xml
      _(identifier).wont_be_nil
      _(identifier.id).must_equal "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
    end
  end

  describe "#access_policy_from_xml" do
    let(:access_policy_xml) { Nokogiri.Slop(Fixtures["container_acl"]).root.SignedIdentifier.AccessPolicy }

    it "accepts an XML node" do
      subject.access_policy_from_xml access_policy_xml
    end

    it "returns a AccessPolicy instance" do
      access_policy = subject.access_policy_from_xml access_policy_xml
      _(access_policy).must_be_kind_of Azure::Storage::Common::Service::AccessPolicy
    end

    it "sets the properties of the AccessPolicy" do
      access_policy = subject.access_policy_from_xml access_policy_xml

      _(access_policy).wont_be_nil
      _(access_policy.start).must_equal "2009-09-28T08:49:37.0000000Z"
      _(access_policy.expiry).must_equal "2009-09-29T08:49:37.0000000Z"
      _(access_policy.permission).must_equal "rwd"
    end
  end

  describe "#enumeration_results_from_xml" do
    let(:enumeration_results_xml) { Fixtures[:list_containers] }

    describe "when passed an instance of EnumerationResults" do
      let(:enumeration_results) { Azure::Storage::Common::Service::EnumerationResults.new }

      it "parses the XML and populates the provided EnumerationResults instance" do
        result = subject.enumeration_results_from_xml enumeration_results_xml, enumeration_results
        _(result).must_be :kind_of?, Azure::Storage::Common::Service::EnumerationResults
        _(result.continuation_token).must_equal "video"
      end

      it "returns the same instance provided" do
        result = subject.enumeration_results_from_xml enumeration_results_xml, enumeration_results
        _(result).must_equal enumeration_results
      end
    end

    describe "when passed nil" do
      it "returns a new instance of EnumerationResults" do
        result = subject.enumeration_results_from_xml enumeration_results_xml, nil
        _(result).must_be_kind_of Azure::Storage::Common::Service::EnumerationResults
      end
    end
  end

  describe "#metadata_from_xml" do
    let(:list_containers_xml) { Fixtures["list_containers"] }
    let(:metadata_xml_node) { Nokogiri.Slop(list_containers_xml).root.Containers.Container[1].Metadata }

    it "converts a Metadata XML element to a Hash" do
      _(subject.metadata_from_xml(metadata_xml_node)).must_be_kind_of Hash
    end

    it "uses the child element names as keys" do
      hash = subject.metadata_from_xml(metadata_xml_node)
      _(hash.has_key?("mymetadata1")).must_equal true
      _(hash.has_key?("mymetadata2")).must_equal true
      _(hash.has_key?("x-ms-invalid-name")).must_equal true
    end

    it "uses the child element text contents as values" do
      hash = subject.metadata_from_xml(metadata_xml_node)
      _(hash["mymetadata1"]).must_equal "first value"
      _(hash["mymetadata2"]).must_equal "second value"
    end

    describe "when it encounters more than one of the same element name" do
      it "returns and array of values for that key" do
        hash = subject.metadata_from_xml(metadata_xml_node)
        _(hash["x-ms-invalid-name"]).must_be_kind_of Array
        _(hash["x-ms-invalid-name"]).must_equal ["invalid-metadata-name", "invalid-metadata-name2"]
      end
    end
  end

  describe "#metadata_from_headers" do
    let(:headers) { {"Content-Type" => "application/xml", "Content-Length" => "37"} }

    let(:metadata_headers) { headers.merge("x-ms-meta-MyMetadata1" => "first value", "x-ms-meta-MyMetadata2" => "second value") }

    it "returns a Hash" do
      _(subject.metadata_from_headers(metadata_headers)).must_be_kind_of Hash
    end

    it "extracts metadata from a Hash for keys that start with x-ms-meta-* and removes that prefix" do
      hash = subject.metadata_from_headers(metadata_headers)
      _(hash.has_key?("MyMetadata1")).must_equal true
      _(hash.has_key?("MyMetadata2")).must_equal true
    end

    it "sets the metadata values to the corresponding header values" do
      hash = subject.metadata_from_headers(metadata_headers)
      _(hash["MyMetadata1"]).must_equal "first value"
      _(hash["MyMetadata2"]).must_equal "second value"
    end
  end

  describe "#retention_policy_to_xml" do
    let(:retention_policy) {
      retention_policy = Azure::Storage::Common::Service::RetentionPolicy.new
      retention_policy.enabled = true
      retention_policy.days = 7

      retention_policy
    }

    let(:retention_policy_xml) { Fixtures["retention_policy"] }

    it "accepts a RetentionPolicy instance and an Nokogiri::XML::Builder instance" do
      Nokogiri::XML::Builder.new do |xml|
        subject.retention_policy_to_xml retention_policy, xml
      end
    end

    it "adds to the XML Builder, which will create the XML graph of the provided values" do
      builder = Nokogiri::XML::Builder.new do |xml|
        subject.retention_policy_to_xml retention_policy, xml
      end
      _(builder.to_xml).must_equal retention_policy_xml
    end
  end

  describe "#retention_policy_from_xml" do
    let(:retention_policy_xml) { Nokogiri.Slop(Fixtures["storage_service_properties"]).root.HourMetrics.RetentionPolicy }

    it "accepts an XML Node" do
      subject.retention_policy_from_xml retention_policy_xml
    end

    it "returns an RetentionPolicy instance" do
      retention_policy = subject.retention_policy_from_xml retention_policy_xml
      _(retention_policy).wont_be_nil
      _(retention_policy).must_be_kind_of Azure::Storage::Common::Service::RetentionPolicy
    end

    it "sets the properties of the RetentionPolicy instance" do
      retention_policy = subject.retention_policy_from_xml retention_policy_xml
      _(retention_policy.enabled).must_equal true
      _(retention_policy.days).must_equal 7
    end
  end

  describe "#hour_metrics_to_xml" do
    let(:metrics) {
      metrics = Azure::Storage::Common::Service::Metrics.new
      metrics.version = "1.0"
      metrics.enabled = true
      metrics.include_apis = false
      retention_policy = metrics.retention_policy = Azure::Storage::Common::Service::RetentionPolicy.new
      retention_policy.enabled = true
      retention_policy.days = 7

      metrics
    }

    let(:metrics_xml) { Fixtures["metrics"] }

    it "accepts a Metrics instance and an Nokogiri::XML::Builder instance" do
      Nokogiri::XML::Builder.new do |xml|
        subject.hour_metrics_to_xml metrics, xml
      end
    end

    it "adds to the XML Builder, which will create the XML graph of the provided values" do
      builder = Nokogiri::XML::Builder.new do |xml|
        subject.hour_metrics_to_xml metrics, xml
      end
      _(builder.to_xml).must_equal metrics_xml
    end
  end

  describe "#metrics_from_xml" do
    let(:metrics_xml) { Nokogiri.Slop(Fixtures["storage_service_properties"]).root.HourMetrics }
    let(:mock_retention_policy) { mock }

    before {
      subject.expects(:retention_policy_from_xml).returns(mock_retention_policy)
    }

    it "accepts an XML Node" do
      subject.metrics_from_xml metrics_xml
    end

    it "returns an Metrics instance" do
      metrics = subject.metrics_from_xml metrics_xml
      _(metrics).wont_be_nil
      _(metrics).must_be_kind_of Azure::Storage::Common::Service::Metrics
    end

    it "sets the properties of the Metrics instance" do
      metrics = subject.metrics_from_xml metrics_xml
      _(metrics.version).must_equal "1.0"
      _(metrics.enabled).must_equal true
      _(metrics.include_apis).must_equal false
      _(metrics.retention_policy).must_equal mock_retention_policy
    end
  end

  describe "#logging_to_xml" do
    let(:logging) {
      logging = Azure::Storage::Common::Service::Logging.new
      logging.version = "1.0"
      logging.delete = true
      logging.read = false
      logging.write = true

      retention_policy = logging.retention_policy = Azure::Storage::Common::Service::RetentionPolicy.new
      retention_policy.enabled = true
      retention_policy.days = 7

      logging
    }

    let(:logging_xml) { Fixtures["logging"] }

    it "accepts a Logging instance and an Nokogiri::XML::Builder instance" do
      Nokogiri::XML::Builder.new do |xml|
        subject.logging_to_xml logging, xml
      end
    end

    it "adds to the XML Builder, which will create the XML graph of the provided values" do
      builder = Nokogiri::XML::Builder.new do |xml|
        subject.logging_to_xml logging, xml
      end
      _(builder.to_xml).must_equal logging_xml
    end
  end

  describe "#logging_from_xml" do
    let(:logging_xml) { Nokogiri.Slop(Fixtures["storage_service_properties"]).root.Logging }
    let(:mock_retention_policy) { mock }

    before {
      subject.expects(:retention_policy_from_xml).returns(mock_retention_policy)
    }

    it "accepts an XML Node" do
      subject.logging_from_xml logging_xml
    end

    it "returns an Logging instance" do
      logging = subject.logging_from_xml logging_xml
      _(logging).wont_be_nil
      _(logging).must_be_kind_of Azure::Storage::Common::Service::Logging
    end

    it "sets the properties of the Logging instance" do
      logging = subject.logging_from_xml logging_xml
      _(logging.version).must_equal "1.0"
      _(logging.delete).must_equal true
      _(logging.read).must_equal false
      _(logging.write).must_equal true
      _(logging.retention_policy).must_equal mock_retention_policy
    end
  end

  describe "#service_properties_to_xml" do
    let(:service_properties) {
      service_properties = Azure::Storage::Common::Service::StorageServiceProperties.new
      service_properties.default_service_version = "2011-08-18"
      logging = service_properties.logging = Azure::Storage::Common::Service::Logging.new
      logging.version = "1.0"
      logging.delete = true
      logging.read = false
      logging.write = true
      retention_policy = logging.retention_policy = Azure::Storage::Common::Service::RetentionPolicy.new
      retention_policy.enabled = true
      retention_policy.days = 7

      metrics = service_properties.hour_metrics = Azure::Storage::Common::Service::Metrics.new
      metrics.version = "1.0"
      metrics.enabled = true
      metrics.include_apis = false
      retention_policy = metrics.retention_policy = Azure::Storage::Common::Service::RetentionPolicy.new
      retention_policy.enabled = true
      retention_policy.days = 7

      service_properties.minute_metrics = metrics

      service_properties.cors = Azure::Storage::Common::Service::Cors.new do |cors|
        cors.cors_rules = []
        cors.cors_rules.push(Azure::Storage::Common::Service::CorsRule.new { |cors_rule|
          cors_rule.allowed_origins = ["http://www.contoso.com", "http://dummy.uri"]
          cors_rule.allowed_methods = ["PUT", "HEAD"]
          cors_rule.max_age_in_seconds = 5
          cors_rule.exposed_headers = ["x-ms-*"]
          cors_rule.allowed_headers = ["x-ms-blob-content-type", "x-ms-blob-content-disposition"]
        })

        cors.cors_rules.push(Azure::Storage::Common::Service::CorsRule.new { |cors_rule|
          cors_rule.allowed_origins = ["*"]
          cors_rule.allowed_methods = ["PUT", "GET"]
          cors_rule.max_age_in_seconds = 5
          cors_rule.exposed_headers = ["x-ms-*"]
          cors_rule.allowed_headers = ["x-ms-blob-content-type", "x-ms-blob-content-disposition"]
        })

        cors.cors_rules.push(Azure::Storage::Common::Service::CorsRule.new { |cors_rule|
          cors_rule.allowed_origins = ["http://www.contoso.com"]
          cors_rule.allowed_methods = ["GET"]
          cors_rule.max_age_in_seconds = 5
          cors_rule.exposed_headers = ["x-ms-*"]
          cors_rule.allowed_headers = ["x-ms-client-request-id"]
        })
      end

      service_properties
    }

    let(:service_properties_xml) { Fixtures["storage_service_properties"] }

    it "accepts a StorageServiceProperties instance" do
      subject.service_properties_to_xml service_properties
    end

    it "returns a XML graph of the provided values" do
      xml = subject.service_properties_to_xml service_properties
      _(xml).must_equal service_properties_xml
    end
  end

  describe "#service_properties_from_xml" do
    let(:service_properties_xml) { Fixtures["storage_service_properties"] }
    let(:mock_logging) { mock }
    let(:mock_metrics) { mock }
    let(:mock_cors) { mock }

    before {
      subject.expects(:logging_from_xml).returns(mock_logging)
      subject.expects(:metrics_from_xml).twice.returns(mock_metrics)
      subject.expects(:cors_from_xml).returns(mock_cors)
    }

    it "accepts an XML string" do
      subject.service_properties_from_xml service_properties_xml
    end

    it "returns an StorageServiceProperties instance" do
      service_properties = subject.service_properties_from_xml service_properties_xml
      _(service_properties).wont_be_nil
      _(service_properties).must_be_kind_of Azure::Storage::Common::Service::StorageServiceProperties
    end

    it "sets the properties of the StorageServiceProperties instance" do
      service_properties = subject.service_properties_from_xml service_properties_xml
      _(service_properties.logging).must_equal mock_logging
      _(service_properties.hour_metrics).must_equal mock_metrics
      _(service_properties.minute_metrics).must_equal mock_metrics
    end
  end

  describe "#to_bool" do
    it "converts a valid string value to a Boolean" do
      _(subject.to_bool("true")).must_be_kind_of TrueClass
      _(subject.to_bool("false")).must_be_kind_of FalseClass
    end

    it "is case insensitive" do
      # mixed case
      _(subject.to_bool("True")).must_equal true

      # upper case
      _(subject.to_bool("TRUE")).must_equal true
    end

    it "returns false for any value other than 'true'" do
      _(subject.to_bool("random string")).must_equal false
      _(subject.to_bool(nil)).must_equal false
    end
  end

  describe "#slopify" do
    let(:xml_data) { '<?xml version="1.0" encoding="utf-8"?><Foo></Foo>' }
    let(:document) { Nokogiri.Slop xml_data }
    let(:root_node) { document.root }
    let(:non_slop_node) { Nokogiri.parse(xml_data).root }

    describe "when passed a String" do
      it "parses the string into a Nokogiri::XML::Element node" do
        result = subject.slopify(xml_data)
        _(result).must_be_kind_of Nokogiri::XML::Element
      end

      it "returns the root of the parsed Document" do
        result = subject.slopify(xml_data)
        _(result.name).must_equal root_node.name
      end

      it "enables Nokogiri 'Slop' mode on the returned Element" do
        result = subject.slopify(xml_data)
        _(result).must_respond_to :method_missing
      end
    end

    describe "when passed a Nokogiri::XML::Document" do
      it "returns a Nokogiri::XML::Element node" do
        result = subject.slopify(document)
        _(result).must_be_kind_of Nokogiri::XML::Element
      end

      it "returns the root of the Document" do
        result = subject.slopify(document)
        _(result.name).must_equal root_node.name
      end

      it "enables Nokogiri 'Slop' mode on the returned Element" do
        result = subject.slopify(xml_data)
        _(result).must_respond_to :method_missing
      end
    end

    describe "when passed a Nokogiri::XML::Element" do
      it "returns the Element unchanged" do
        result = subject.slopify(root_node)
        _(result).must_equal root_node
      end

      it "does not enable Nokogiri 'Slop' mode on the returned Element if it didn't already have it" do
        result = subject.slopify(root_node)
        _(result.respond_to?(:method_missing)).must_equal root_node.respond_to?(:method_missing)

        result = subject.slopify(non_slop_node)
        _(result.respond_to?(:method_missing)).must_equal non_slop_node.respond_to?(:method_missing)
      end
    end
  end

  describe "#expect_node" do
    let(:node) { mock }
    it "throws an error if the xml node doesn't match the passed element name" do
      node.expects(:name).returns("NotFoo")
      assert_raises RuntimeError do
        subject.expect_node("Foo", node)
      end
    end
  end
end
