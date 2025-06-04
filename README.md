# Fault Event Processor - Senior Backend Engineer Interview

## Overview

Welcome to the ChargerHelp! technical interview! You'll be building a fault event processing system that intelligently triages charging station issues and orchestrates appropriate responses.

## Business Context

ChargerHelp! monitors thousands of EV charging stations across the country. When stations experience issues (faults), our system receives raw event data from various sources. The system needs to quickly determine the appropriate response:

- **Immediate technician dispatch** for critical issues
- **Customer notifications** for service disruptions  
- **Monitoring and tracking** for minor issues
- **Escalation** for unreachable stations

Different customers have different SLA requirements, and some fault types are more urgent than others.

## System Architecture

Here's how fault events flow through the system:

```
Raw Event Data → FaultEventProcessor → Business Rules → Actions + FaultEvent Record
      ↓               ↓                    ↓              ↓           ↓
  JSON Input    Analyze Fault      Apply SLA Rules   Dispatch    Save to DB
              Check Source       Determine Urgency   Notify     Track Results  
              Validate Data      Route Appropriately Escalate   Audit Trail
```

**Input:** Raw fault event data (JSON) from monitoring systems  
**Processing:** `FaultEventProcessor.process(event_data)` applies business rules  
**Output:** Result object containing actions to take + persisted `FaultEvent` record

## What You'll Build

Your task is to implement the **fault event processing logic** that receives raw fault event data and intelligently decides what actions to take while persisting the processing results.

### Core Challenge
When raw fault event data comes in, your system should:
1. **Analyze the fault** (type, source, customer, alarm status)
2. **Apply business rules** (customer SLA, fault severity, source behavior)
3. **Trigger appropriate actions** (dispatch, notify, escalate, monitor)
4. **Create a FaultEvent record** to persist the event data and processing results

### Key Scenarios to Handle
- **"NEEDS SERVICE"** → Dispatch technician immediately + create FaultEvent record
- **"NO SERVICE NEEDED"** → Log for monitoring + create FaultEvent record with minimal actions
- **"UNREACHABLE"** → Escalate to operations team + create FaultEvent record
- **Different customer SLAs** → 2-hour vs 4-hour response requirements
- **Source differences** → ChargePoint vs Synop fault behaviors

## Setup Instructions

### Prerequisites
- Ruby 3.0+
- PostgreSQL
- Git

### Getting Started

1. **Clone and setup:**
   ```bash
   git clone [repository-url]
   cd fault-event-processor
   bundle install
   ```

2. **Database setup:**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

3. **Start the server:**
   ```bash
   rails server
   ```

4. **Verify setup:**
   ```bash
   ruby script/test_fault_processing.rb
   ```

## Data Structure

### Sample Raw Fault Event Input
```json
{
  "id_from_source": 19824588,
  "customer_id": 1,
  "location_asset_id": 1,
  "connector_id": 2,
  "fault_time": "2025-06-04T14:53:13.000Z",
  "resolved_at": null,
  "status": "NEEDS SERVICE",
  "downtime_type": "NEEDS SERVICE",
  "fault_type": "Ground Fault Circuit Interrupter",
  "source": "chargepoint",
  "is_alarm": true
}
```

### Key Models
- **Customer** - Has SLA requirements (2-hour vs 4-hour response)
- **LocationAsset** - The charging station experiencing the fault
- **FaultEvent** - Persistent record created by the processor containing both the original event data and processing results

### FaultEvent Model Structure
The `FaultEvent` model stores both the original event data and processing results:

**Original Event Data:**
- `id_from_source` - Unique identifier from the source system
- `customer_id`, `location_asset_id` - References to related entities
- `connector_id` - Specific connector (nullable for station-wide issues)
- `fault_time`, `resolved_at` - Timing information
- `status`, `downtime_type`, `fault_type` - Fault classification
- `source` - Source system (chargepoint, synop, etc.)
- `is_alarm` - Whether this is an alarm event

**Processing Results:**
- `urgency_level` - Computed urgency: critical, high, medium, low, info, resolved
- `response_time_hours` - SLA-based response time requirement
- `actions_taken` - Array of actions triggered (dispatch_technician, notify_customer, etc.)
- `station_wide` - Boolean indicating if fault affects entire station
- `processed_at` - Timestamp when processing occurred

**Schema Migration:**
```bash
rails db:migrate  # Run existing migrations
# New attributes are added via: AddProcessingAttributesToFaultEvents migration
```

## Test-Driven Development Workflow

The API endpoint at `POST /api/v1/fault_events` currently just accepts requests. **Your job is to implement the intelligent processing logic that creates FaultEvent records with processing results using TDD.**

We've provided a comprehensive test suite in `spec/models/fault_event_processor_spec.rb` with realistic scenarios you'll encounter in production. These tests are currently pending - your task is to make them pass.

### Step-by-Step Workflow

1. **See all scenarios you need to handle:**
   ```bash
   bundle exec rspec spec/models/fault_event_processor_spec.rb
   ```

2. **Create the FaultEventProcessor class:**
   ```bash
   touch app/models/fault_event_processor.rb
   ```

3. **Work on one test at a time:**
   ```bash
   # Start with critical safety response
   bundle exec rspec spec/models/fault_event_processor_spec.rb:20 -fd
   ```

4. **Watch tests turn green as you build features**

5. **Test via API once logic is working:**
   ```bash
   ruby script/test_fault_processing.rb
   
   # Or test manually
   curl -X POST http://localhost:3000/api/v1/fault_events \
     -H "Content-Type: application/json" \
     -d '{"customer_id": 1, "location_asset_id": 1, "status": "NEEDS SERVICE", ...}'
   ```

## Seeded Test Data

The database includes sample customers and charging stations. To see the exact IDs after seeding:

```bash
rails console
# Then run:
Customer.all.pluck(:id, :name, :sla_response_hours)
LocationAsset.all.pluck(:id, :name, :customer_id)
```

Expected customers:
- **Fast Response Corp** - 2-hour SLA
- **Standard Service LLC** - 4-hour SLA  

## Session Structure

1. **Setup & Context (15 min)** - Review this README and codebase
2. **Architecture Discussion (15 min)** - Plan your approach
3. **Implementation (80 min)** - Build the fault processing logic
4. **Wrap-up (10 min)** - Discuss what we accomplished

## Success Criteria

### Minimum Viable Implementation (60-80 minutes)
✅ **Core Functionality:**
- `FaultEventProcessor.process(fault_event)` method exists and works
- Handles basic fault statuses: "NEEDS SERVICE", "NO SERVICE NEEDED", "UNREACHABLE"
- Returns structured result with `actions`, `urgency`, and `response_time_hours`
- At least 3-5 test scenarios passing

✅ **Business Logic:**
- Different actions for different fault statuses (dispatch vs monitor vs escalate)
- Customer SLA integration (2-hour vs 4-hour response times)
- Basic urgency classification (critical, high, medium, low)

✅ **Code Quality:**
- Clean, readable implementation
- Proper separation of concerns
- Test-driven development approach

### Stretch Goals (If time permits)
🎯 **Advanced Features:**
- Source-specific logic (ChargePoint vs Synop differences)
- Alarm status consideration (`is_alarm: true/false`)
- Duplicate event handling
- More sophisticated urgency rules

🎯 **Architecture:**
- Separate classes for rules engine or action orchestration
- Mock external service integrations
- Error handling for edge cases

### Success Indicators by Time
- **30 minutes:** Basic `FaultEventProcessor` class with first test passing
- **60 minutes:** Core business rules implemented, 5+ tests passing
- **80 minutes:** SLA handling working, most scenarios covered
- **If ahead:** Working on stretch goals and refinements

### What We Don't Expect
❌ Full production-ready error handling  
❌ Complete external service integrations  
❌ UI or extensive API endpoints  
❌ Performance optimization  
❌ Comprehensive edge case coverage

The goal is demonstrating **problem-solving approach** and **business logic implementation** within a realistic timeframe, not building a complete production system.

## What We're Evaluating

- **Problem-solving approach** - How you break down the requirements
- **Rails skills** - API design, models, and business logic patterns
- **Business logic implementation** - Rules that make sense for the domain
- **Code quality** - Clean, testable, maintainable code
- **Collaboration** - How we work together during implementation

## Architecture Suggestions

Based on the test scenarios, you might want to create:

- **FaultEventProcessor** - Main processing class (start here!)
- **Triage rules engine** - Decision-making logic for urgency/actions
- **Action orchestrator** - Coordinate downstream actions
- **Result object** - Structure to return processing results
- **Mock external services** - Simulate dispatch, notifications, etc.

The tests will guide your implementation - start with the simplest scenario and build up complexity.

Consider these questions as you build:

- How do you handle different customer SLA requirements?
- What makes a fault "urgent" vs "routine"?
- How do ChargePoint faults differ from Synop faults?
- When should you escalate vs dispatch vs just monitor?
- How do you track what actions were taken?
- What happens if external services (dispatch, notifications) fail?
- How do you handle duplicate events?

## Available Tools

Feel free to use any resources you normally would:
- AI assistants (ChatGPT, Claude, etc.)
- Google, Stack Overflow, documentation
- Any gems or patterns you prefer

We're interested in your problem-solving process and implementation approach, not memorization.

---

## Reference: Implementation Details

### Expected Result Structure
The test suite expects a `FaultEventProcessor` class with a `process` method that returns a result object with properties like:

```ruby
# Expected return structure (design this however makes sense)
result.fault_event     # FaultEvent record created/updated in database
result.actions         # Array of actions: ['dispatch_technician', 'notify_customer']
result.urgency         # String: 'critical', 'high', 'medium', 'low', 'info'
result.response_time_hours # Integer: based on customer SLA
result.ticket_action   # String: 'create_new', 'update_existing'
result.success         # Boolean: whether processing was successful
```

The `FaultEvent` model should store:
- Original event data (id_from_source, fault_time, status, etc.)
- Processing results (actions_taken, urgency_level, response_time_hours)
- Timestamps and audit information

### Running Tests
```bash
# Run the full test suite
bundle exec rspec

# Run just the fault processor tests
bundle exec rspec spec/models/fault_event_processor_spec.rb
```

---

**Ready to start?** Take a few minutes to explore the codebase, then let's discuss your approach!