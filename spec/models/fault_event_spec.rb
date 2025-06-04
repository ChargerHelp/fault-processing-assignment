require 'rails_helper'

RSpec.describe FaultEvent, type: :model do
  let(:customer) { Customer.create!(name: "Test Customer", sla_hours: 4) }
  let(:location) { Location.create!(name: "Test Location", customer: customer) }
  let(:location_asset) { LocationAsset.create!(name: "Test Asset", location: location, customer: customer) }

  describe "associations" do
    it "belongs to customer" do
      fault_event = FaultEvent.new
      expect(fault_event).to respond_to(:customer)
      expect(FaultEvent.reflect_on_association(:customer).macro).to eq(:belongs_to)
    end

    it "belongs to location_asset" do
      fault_event = FaultEvent.new
      expect(fault_event).to respond_to(:location_asset)
      expect(FaultEvent.reflect_on_association(:location_asset).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    subject do
      FaultEvent.new(
        customer: customer,
        location_asset: location_asset,
        fault_time: Time.current,
        status: "NEEDS SERVICE",
        fault_type: "Test Fault",
        source: "test"
      )
    end

    it "validates presence of fault_time" do
      subject.fault_time = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:fault_time]).to include("can't be blank")
    end

    it "validates presence of status" do
      subject.status = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:status]).to include("can't be blank")
    end

    it "validates presence of fault_type" do
      subject.fault_type = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:fault_type]).to include("can't be blank")
    end

    it "validates presence of source" do
      subject.source = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:source]).to include("can't be blank")
    end

    it "validates inclusion of urgency_level" do
      subject.urgency_level = "invalid"
      expect(subject).not_to be_valid
      expect(subject.errors[:urgency_level]).to include("is not included in the list")
    end

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is invalid without fault_time" do
      subject.fault_time = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:fault_time]).to include("can't be blank")
    end

    it "is invalid without status" do
      subject.status = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:status]).to include("can't be blank")
    end

    it "is invalid without fault_type" do
      subject.fault_type = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:fault_type]).to include("can't be blank")
    end

    it "is invalid without source" do
      subject.source = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:source]).to include("can't be blank")
    end

    it "is invalid with invalid urgency_level" do
      subject.urgency_level = "invalid"
      expect(subject).not_to be_valid
      expect(subject.errors[:urgency_level]).to include("is not included in the list")
    end

    it "is valid with valid urgency_level values" do
      %w[critical high medium low info resolved].each do |level|
        subject.urgency_level = level
        expect(subject).to be_valid
      end
    end

    it "is valid with blank urgency_level" do
      subject.urgency_level = nil
      expect(subject).to be_valid
    end
  end

  describe "serialization" do
    let(:fault_event) do
      FaultEvent.create!(
        customer: customer,
        location_asset: location_asset,
        fault_time: Time.current,
        status: "NEEDS SERVICE",
        fault_type: "Test Fault",
        source: "test",
        actions_taken: [ "dispatch_technician", "notify_customer" ]
      )
    end

    it "serializes and deserializes actions_taken as an array" do
      expect(fault_event.actions_taken).to eq([ "dispatch_technician", "notify_customer" ])
      expect(fault_event.actions_taken).to be_a(Array)
    end

    it "persists the serialized array to the database" do
      fault_event.reload
      expect(fault_event.actions_taken).to eq([ "dispatch_technician", "notify_customer" ])
    end

    it "handles empty arrays" do
      fault_event.update!(actions_taken: [])
      fault_event.reload
      expect(fault_event.actions_taken).to eq([])
    end

    it "handles nil values" do
      fault_event.update!(actions_taken: nil)
      fault_event.reload
      expect(fault_event.actions_taken).to be_nil
    end

    it "can store complex array data" do
      complex_actions = [
        "dispatch_technician",
        "notify_customer",
        "escalate_to_ops",
        "log_unknown_error"
      ]
      fault_event.update!(actions_taken: complex_actions)
      fault_event.reload
      expect(fault_event.actions_taken).to eq(complex_actions)
    end
  end

  describe "scopes" do
    let!(:fault_event_1) { FaultEvent.create!(customer: customer, location_asset: location_asset, fault_time: Time.current, status: "ACTIVE", fault_type: "Test", source: "test", id_from_source: 123) }
    let!(:fault_event_2) { FaultEvent.create!(customer: customer, location_asset: location_asset, fault_time: Time.current, status: "ACTIVE", fault_type: "Test", source: "test", id_from_source: 456) }

    describe ".by_source_id" do
      it "finds events by source ID" do
        results = FaultEvent.by_source_id(123)
        expect(results).to include(fault_event_1)
        expect(results).not_to include(fault_event_2)
      end

      it "returns empty collection when no match" do
        results = FaultEvent.by_source_id(999)
        expect(results).to be_empty
      end
    end
  end

  describe "instance methods" do
    let(:fault_event) do
      FaultEvent.new(
        customer: customer,
        location_asset: location_asset,
        fault_time: Time.current,
        status: "NEEDS SERVICE",
        fault_type: "Test Fault",
        source: "test"
      )
    end

    describe "#resolved?" do
      it "returns false when resolved_at is nil" do
        fault_event.resolved_at = nil
        expect(fault_event.resolved?).to be false
      end

      it "returns true when resolved_at is present" do
        fault_event.resolved_at = Time.current
        expect(fault_event.resolved?).to be true
      end
    end

    describe "#critical_safety_issue?" do
      it "returns true for Ground Fault issues" do
        fault_event.fault_type = "Ground Fault Circuit Interrupter"
        expect(fault_event.critical_safety_issue?).to be true
      end

      it "returns true when urgency_level is critical" do
        fault_event.urgency_level = "critical"
        fault_event.fault_type = "Regular Fault"
        expect(fault_event.critical_safety_issue?).to be true
      end

      it "returns false for non-critical issues" do
        fault_event.fault_type = "Regular Fault"
        fault_event.urgency_level = "medium"
        expect(fault_event.critical_safety_issue?).to be false
      end

      it "handles nil fault_type gracefully" do
        fault_event.fault_type = nil
        fault_event.urgency_level = "medium"
        expect(fault_event.critical_safety_issue?).to be false
      end
    end
  end

  describe "database persistence" do
    it "can be created and saved successfully" do
      fault_event = FaultEvent.new(
        customer: customer,
        location_asset: location_asset,
        fault_time: Time.current,
        status: "NEEDS SERVICE",
        fault_type: "Test Fault",
        source: "test",
        urgency_level: "high",
        actions_taken: [ "dispatch_technician" ]
      )

      expect(fault_event.save).to be true
      expect(fault_event.persisted?).to be true
      expect(fault_event.id).to be_present
    end

    it "maintains data integrity after save and reload" do
      original_time = Time.current
      fault_event = FaultEvent.create!(
        customer: customer,
        location_asset: location_asset,
        fault_time: original_time,
        status: "NEEDS SERVICE",
        fault_type: "Test Fault",
        source: "test",
        urgency_level: "high",
        actions_taken: [ "dispatch_technician", "notify_customer" ]
      )

      reloaded = FaultEvent.find(fault_event.id)
      expect(reloaded.customer).to eq(customer)
      expect(reloaded.location_asset).to eq(location_asset)
      expect(reloaded.fault_time.to_i).to eq(original_time.to_i)
      expect(reloaded.status).to eq("NEEDS SERVICE")
      expect(reloaded.fault_type).to eq("Test Fault")
      expect(reloaded.source).to eq("test")
      expect(reloaded.urgency_level).to eq("high")
      expect(reloaded.actions_taken).to eq([ "dispatch_technician", "notify_customer" ])
    end
  end
end
