require 'rails_helper'

RSpec.describe FaultProcessor do
  let(:customer_fast_response) do
    Customer.create!(name: "Fast Response Corp", sla_hours: 2)
  end

  let(:customer_standard) do
    Customer.create!(name: "Standard Service LLC", sla_hours: 4)
  end

  let(:location_downtown) do
    Location.create!(name: "Downtown Station", customer: customer_fast_response)
  end

  let(:location_mall) do
    Location.create!(name: "Mall Charging Hub", customer: customer_standard)
  end

  let(:asset_downtown) do
    LocationAsset.create!(
      name: "Station A",
      location: location_downtown,
      customer: customer_fast_response
    )
  end

  let(:asset_mall) do
    LocationAsset.create!(
      name: "Station B",
      location: location_mall,
      customer: customer_standard
    )
  end

  describe "Critical Safety Response" do
    let(:ground_fault_event) do
      {
        id_from_source: 19824588,
        customer_id: customer_fast_response.id,
        location_asset_id: asset_downtown.id,
        connector_id: 2,
        fault_time: "2025-06-04T14:53:13.000Z",
        resolved_at: nil,
        status: "NEEDS SERVICE",
        downtime_type: "NEEDS SERVICE",
        fault_type: "Ground Fault Circuit Interrupter",
        source: "chargepoint",
        is_alarm: true
      }
    end

    it "dispatches technician immediately for ground faults" do
      pending "Implement FaultProcessor.process method"

      result = FaultProcessor.process(ground_fault_event)

      expect(result.actions).to include('dispatch_technician')
      expect(result.urgency).to eq('critical')
      expect(result.actions).to include('notify_customer')

      # Expect a FaultEvent record is created
      expect(result.fault_event).to be_persisted
      expect(result.fault_event.id_from_source).to eq(19824588)
      expect(result.fault_event.urgency_level).to eq('critical')
      expect(result.fault_event.actions_taken).to include('dispatch_technician')
    end

    it "overrides customer SLA for safety issues" do
      pending "Safety issues should ignore normal SLA rules"

      result = FaultProcessor.process(ground_fault_event)

      expect(result.response_time_hours).to be <= 1
      expect(result.priority).to eq('immediate')

      # Expect FaultEvent record reflects the overridden SLA
      expect(result.fault_event.response_time_hours).to be <= 1
    end
  end

  describe "SLA-Based Processing" do
    let(:payment_error_event) do
      {
        id_from_source: 19824590,
        customer_id: nil, # Will be set in each test
        location_asset_id: nil, # Will be set in each test
        connector_id: 1,
        fault_time: "2025-06-04T15:30:12.000Z",
        resolved_at: nil,
        status: "NEEDS SERVICE",
        downtime_type: "NEEDS SERVICE",
        fault_type: "Payment Terminal Error",
        source: "chargepoint",
        is_alarm: true
      }
    end

    it "processes 2-hour SLA customer with high urgency" do
      pending "Implement SLA-aware processing"

      event = payment_error_event.merge(
        customer_id: customer_fast_response.id,
        location_asset_id: asset_downtown.id
      )

      result = FaultProcessor.process(event)

      expect(result.urgency).to eq('high')
      expect(result.response_time_hours).to eq(2)
      expect(result.actions).to include('dispatch_technician_urgent')

      # Expect FaultEvent record stores SLA-based processing results
      expect(result.fault_event).to be_persisted
      expect(result.fault_event.response_time_hours).to eq(2)
      expect(result.fault_event.urgency_level).to eq('high')
    end

    it "processes 4-hour SLA customer with standard urgency" do
      pending "Different SLA should result in different urgency"

      event = payment_error_event.merge(
        customer_id: customer_standard.id,
        location_asset_id: asset_mall.id
      )

      result = FaultProcessor.process(event)

      expect(result.urgency).to eq('medium')
      expect(result.response_time_hours).to eq(4)
      expect(result.actions).to include('dispatch_technician_standard')

      # Expect FaultEvent record stores SLA-based processing results
      expect(result.fault_event).to be_persisted
      expect(result.fault_event.response_time_hours).to eq(4)
      expect(result.fault_event.urgency_level).to eq('medium')
    end
  end

  describe "No-Action Scenarios" do
    let(:minor_issue_event) do
      {
        id_from_source: 19824587,
        customer_id: customer_fast_response.id,
        location_asset_id: asset_downtown.id,
        connector_id: 1,
        fault_time: "2025-06-04T14:50:23.000Z",
        resolved_at: nil,
        status: "NO SERVICE NEEDED",
        downtime_type: "NO SERVICE NEEDED",
        fault_type: "Circuit Sharing Load Decreased",
        source: "chargepoint",
        is_alarm: true
      }
    end

    it "only logs minor operational changes" do
      pending "Minor issues should not trigger dispatch"

      result = FaultProcessor.process(minor_issue_event)

      expect(result.actions).to eq([ 'log_and_monitor' ])
      expect(result.urgency).to eq('low')
      expect(result.actions).not_to include('dispatch_technician')

      # Expect FaultEvent record is still created for tracking
      expect(result.fault_event).to be_persisted
      expect(result.fault_event.urgency_level).to eq('low')
      expect(result.fault_event.actions_taken).to eq([ 'log_and_monitor' ])
    end

    let(:informational_event) do
      {
        id_from_source: 19824594,
        customer_id: customer_standard.id,
        location_asset_id: asset_mall.id,
        connector_id: 1,
        fault_time: "2025-06-04T17:00:45.000Z",
        resolved_at: nil,
        status: "NO SERVICE NEEDED",
        downtime_type: "NONE",
        fault_type: "Session Started",
        source: "chargepoint",
        is_alarm: false
      }
    end

    it "only logs non-alarm informational events" do
      pending "Non-alarm events are informational only"

      result = FaultProcessor.process(informational_event)

      expect(result.actions).to eq([ 'log_only' ])
      expect(result.urgency).to eq('info')

      # Expect FaultEvent record is created for audit trail
      expect(result.fault_event).to be_persisted
      expect(result.fault_event.urgency_level).to eq('info')
      expect(result.fault_event.actions_taken).to eq([ 'log_only' ])
    end
  end

  describe "Escalation Scenarios" do
    let(:unreachable_event) do
      {
        id_from_source: 19824589,
        customer_id: customer_standard.id,
        location_asset_id: asset_mall.id,
        connector_id: 1,
        fault_time: "2025-06-04T15:10:45.000Z",
        resolved_at: nil,
        status: "UNREACHABLE_Unreachable",
        downtime_type: "network error",
        fault_type: "Unreachable",
        source: "synop",
        is_alarm: true
      }
    end

    it "escalates unreachable stations to operations" do
      pending "Unreachable stations need immediate ops attention"

      result = FaultProcessor.process(unreachable_event)

      expect(result.actions).to include('escalate_to_ops')
      expect(result.actions).to include('notify_customer')
      expect(result.urgency).to eq('high')

      # Expect FaultEvent record captures escalation details
      expect(result.fault_event).to be_persisted
      expect(result.fault_event.actions_taken).to include('escalate_to_ops')
      expect(result.fault_event.urgency_level).to eq('high')
    end
  end

  describe "Source-Specific Processing" do
    let(:synop_unknown_error) do
      {
        id_from_source: 19824592,
        customer_id: customer_standard.id,
        location_asset_id: asset_mall.id,
        connector_id: 2,
        fault_time: "2025-06-04T16:45:18.000Z",
        resolved_at: nil,
        status: "NEEDS SERVICE",
        downtime_type: "NEEDS SERVICE",
        fault_type: "OtherError_023983",
        source: "synop",
        is_alarm: true
      }
    end

    it "handles Synop unknown errors with additional logging" do
      pending "Synop errors often need manual diagnosis"

      result = FaultProcessor.process(synop_unknown_error)

      expect(result.actions).to include('dispatch_technician')
      expect(result.actions).to include('log_unknown_error')
      expect(result.urgency).to eq('medium')

      # Expect FaultEvent record includes source-specific processing
      expect(result.fault_event).to be_persisted
      expect(result.fault_event.source).to eq('synop')
      expect(result.fault_event.actions_taken).to include('log_unknown_error')
    end

    let(:network_error_event) do
      {
        id_from_source: 19824595,
        customer_id: customer_fast_response.id,
        location_asset_id: asset_downtown.id,
        connector_id: nil, # Station-wide issue
        fault_time: "2025-06-04T17:30:22.000Z",
        resolved_at: nil,
        status: "NEEDS SERVICE",
        downtime_type: "network error",
        fault_type: "network error",
        source: "synop",
        is_alarm: true
      }
    end

    it "handles station-wide network issues" do
      pending "Network errors affect entire station"

      result = FaultProcessor.process(network_error_event)

      expect(result.actions).to include('dispatch_technician')
      expect(result.actions).to include('check_network_status')
      expect(result.station_wide).to be true

      # Expect FaultEvent record indicates station-wide scope
      expect(result.fault_event).to be_persisted
      expect(result.fault_event.station_wide).to be true
      expect(result.fault_event.actions_taken).to include('check_network_status')
    end
  end

  describe "Resolution Processing" do
    let(:auto_resolved_event) do
      {
        id_from_source: 19824593,
        customer_id: customer_fast_response.id,
        location_asset_id: asset_downtown.id,
        connector_id: 1,
        fault_time: "2025-06-04T13:20:15.000Z",
        resolved_at: "2025-06-04T13:25:30.000Z",
        status: "NO SERVICE NEEDED",
        downtime_type: "NONE",
        fault_type: "Temporary Communication Error",
        source: "chargepoint",
        is_alarm: false
      }
    end

    it "closes tickets for auto-resolved faults" do
      pending "Auto-resolved faults should close existing tickets"

      result = FaultProcessor.process(auto_resolved_event)

      expect(result.actions).to include('close_ticket')
      expect(result.actions).to include('log_resolution')
      expect(result.urgency).to eq('resolved')

      # Expect FaultEvent record marks resolution
      expect(result.fault_event).to be_persisted
      expect(result.fault_event.resolved_at).to be_present
      expect(result.fault_event.urgency_level).to eq('resolved')
    end
  end

  describe "Deduplication Logic" do
    let(:original_fault) do
      {
        id_from_source: 19824588,
        customer_id: customer_fast_response.id,
        location_asset_id: asset_downtown.id,
        connector_id: 2,
        fault_time: "2025-06-04T14:53:13.000Z",
        resolved_at: nil,
        status: "NEEDS SERVICE",
        downtime_type: "NEEDS SERVICE",
        fault_type: "Ground Fault Circuit Interrupter",
        source: "chargepoint",
        is_alarm: true
      }
    end

    it "creates new ticket for first occurrence" do
      pending "First fault should create new processing ticket"

      result = FaultProcessor.process(original_fault)

      expect(result.ticket_action).to eq('create_new')
      expect(result.actions).to include('dispatch_technician')

      # Expect new FaultEvent record is created
      expect(result.fault_event).to be_persisted
      expect(result.fault_event).to be_a_new_record == false  # Record was saved
      expect(FaultEvent.where(id_from_source: 19824588).count).to eq(1)
    end

    it "updates existing ticket for duplicate events" do
      pending "Duplicate faults should update existing tickets"

      # Process original fault first
      first_result = FaultProcessor.process(original_fault)
      original_fault_event = first_result.fault_event

      # Process same fault again (same id_from_source)
      result = FaultProcessor.process(original_fault)

      expect(result.ticket_action).to eq('update_existing')
      expect(result.actions).to include('update_existing_ticket')
      expect(result.actions).not_to include('dispatch_technician') # Should not dispatch again

      # Expect existing FaultEvent record is updated, not duplicated
      expect(result.fault_event.id).to eq(original_fault_event.id)
      expect(FaultEvent.where(id_from_source: 19824588).count).to eq(1)
    end
  end

  describe "Error Handling" do
    let(:invalid_customer_event) do
      {
        id_from_source: 99999,
        customer_id: 999, # Non-existent customer
        location_asset_id: asset_downtown.id,
        connector_id: 1,
        fault_time: "2025-06-04T18:00:00.000Z",
        resolved_at: nil,
        status: "NEEDS SERVICE",
        downtime_type: "NEEDS SERVICE",
        fault_type: "Test Error",
        source: "test",
        is_alarm: true
      }
    end

    it "handles invalid customer gracefully" do
      pending "Should handle missing customer data"

      result = FaultProcessor.process(invalid_customer_event)

      expect(result.success).to be false
      expect(result.error).to include('Invalid customer')

      # Expect no FaultEvent record is created for invalid data
      expect(result.fault_event).to be_nil
    end
  end
end
