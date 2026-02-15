# RUNTIME SEQUENCES - TRANSACTION FLOWS

**Architect Execution Framework — Phase 3 Runtime**
**AEGIS Layer 2 — Architecture & Design Layer**
**Deterministic Authorization & State Transition Flows**

---

## Overview

Runtime sequences define how the system behaves during actual operations. Each sequence enforces authority checks, prevents state ambiguity, and ensures all critical actions are auditable.

**Principle**: No skipped authority gates. Every transition is validated.

---

## 1️⃣ PUBLIC PURCHASE FLOW (Happy Path)

```mermaid
sequenceDiagram
    actor Visitor
    participant PublicWeb as Public Web<br/>Application
    participant API as Application<br/>API
    participant CE as Commerce<br/>Engine
    participant IO as Integration<br/>Orchestrator
    participant PG as Payment<br/>Gateway
    participant DB as Primary<br/>Database

    Visitor->>PublicWeb: Add product to cart
    PublicWeb->>API: POST /cart (site_id=123)
    API->>CE: Validate cart & pricing
    CE->>DB: Persist Draft Order
    DB-->>CE: Draft state confirmed
    CE-->>API: Cart updated
    API-->>PublicWeb: Cart rendered

    Visitor->>PublicWeb: Initiate Checkout
    PublicWeb->>API: POST /orders/checkout
    API->>API: Validate visitor context
    API->>CE: Move to Pending_Payment
    CE->>DB: Update order state
    DB-->>CE: State persisted

    API->>IO: Create Payment Session
    IO->>IO: Sign request (idempotency key)
    IO->>PG: POST /authorize
    PG->>PG: Process payment
    PG-->>IO: Webhook (Authorized + Signature)

    IO->>IO: Validate webhook signature
    IO->>API: Payment Authorized Event
    API->>CE: Confirm Payment
    CE->>CE: Validate Pending_Payment state
    CE->>DB: Transition to Payment_Authorized
    CE->>DB: Then Transition to Confirmed
    DB-->>CE: Both updates persisted
    CE-->>API: Order confirmed
    API-->>PublicWeb: Success
    PublicWeb-->>Visitor: Order confirmation

    Note over CE,DB: All DB writes<br/>through API layer<br/>No direct access
    Note over IO,PG: Webhook signature<br/>MUST be validated<br/>before state change
    Note over API,CE: Authority enforced<br/>No AI involved<br/>No admin override
```

### Observations

🔒 **Only Commerce Engine mutates order state**
🔒 **Payment must be validated before confirmation**
🔒 **No AI in flow**
🔒 **No direct DB write from Integration layer**
🔒 **site_id embedded in all requests**
🔒 **Idempotency key prevents duplicate charges**
🔒 **Visitor cannot confirm order without payment**

---

## 2️⃣ PAYMENT FAILURE FLOW

```mermaid
sequenceDiagram
    participant Visitor
    participant PublicWeb
    participant IO as Integration<br/>Orchestrator
    participant PG as Payment<br/>Gateway
    participant API
    participant CE as Commerce<br/>Engine
    participant DB as Database

    Visitor->>PublicWeb: Initiate Checkout
    PublicWeb->>API: POST /orders/checkout
    API->>CE: Move to Pending_Payment
    CE->>DB: Update order state

    API->>IO: Create Payment Session
    IO->>PG: POST /authorize
    PG->>PG: Validation fails
    PG-->>IO: Webhook (Failed + Reason)

    IO->>IO: Validate webhook signature
    IO->>API: Payment Failed Event
    API->>CE: Mark Payment_Failed
    CE->>DB: Update order state
    DB-->>CE: State persisted
    CE-->>API: Failure recorded
    API-->>PublicWeb: Failure response
    PublicWeb-->>Visitor: Display error + retry

    Visitor->>PublicWeb: Retry Checkout
    PublicWeb->>API: POST /orders/{id}/retry
    API->>CE: Validate Payment_Failed state
    CE->>CE: Transition to Pending_Payment
    CE->>DB: Update state
    Note over IO,PG: New payment attempt<br/>with new idempotency key

    Note over CE,DB: Order remains intact
    Note over CE,DB: No partial confirmation
    Note over CE,DB: Blast radius: single order
```

### Containment Strategy

🔒 **Order remains intact** - no partial state
🔒 **No cascade failure** - other orders unaffected
🔒 **Visitor can retry** - 24h recovery window
🔒 **Blast radius: single order only**
🔒 **Admin can manually refund if stuck** - explicit action required
🔒 **All failure reasons logged** - audit trail preserved

---

## 3️⃣ AI ADVISORY SUGGESTION FLOW (AI Enabled Mode)

```mermaid
sequenceDiagram
    actor Admin
    participant AdminWeb as Admin Web<br/>Application
    participant API
    participant AIService as AI Advisory<br/>Service
    participant AIMP as AI Model<br/>Provider
    participant DB as Database

    Admin->>AdminWeb: Request Content Suggestion
    AdminWeb->>API: POST /suggestions (site_id=123)
    API->>API: Check ai_enabled flag
    API->>API: Validate admin authority
    API->>AIService: Generate Suggestion Request

    AIService->>AIService: Check if enabled
    AIService->>AIMP: Inference Call (content)
    AIMP->>AIMP: Process (LLM)
    AIMP-->>AIService: Generated output

    AIService->>DB: Store Suggestion
    Note over AIService,DB: Separate table<br/>site_id scoped<br/>NOT canonical content
    DB-->>AIService: Stored
    AIService-->>API: Suggestion Ready
    API-->>AdminWeb: Return Suggestion
    AdminWeb-->>Admin: Display for review

    Admin->>AdminWeb: Approve Suggestion
    AdminWeb->>API: PUT /suggestions/{id}/approve
    API->>API: Validate admin authority
    API->>DB: Create New Content Version
    Note over API,DB: Approval creates version
    DB-->>API: Version created
    API-->>AdminWeb: Success
    AdminWeb-->>Admin: Content updated

    Admin->>AdminWeb: Reject Suggestion
    AdminWeb->>API: PUT /suggestions/{id}/reject
    API->>DB: Log rejection + reason
    Note over API,DB: Logged for AI<br/>model improvement

    Note over AIService,DB: Canonical content<br/>unchanged until approval
    Note over AIService,DB: AI cannot write<br/>to content tables
    Note over API,DB: All actions audit-logged
    Note over API,DB: site_id enforced
```

### Critical Guarantees

🔒 **Suggestion stored separately** - separate DB table
🔒 **Canonical content unchanged until approval** - immutable until explicit action
🔒 **AI cannot write directly to content tables** - advisory only
🔒 **All suggestions site-scoped** - site_id tagged
🔒 **Admin approval required** - no auto-publish
🔒 **Full audit trail** - timestamp + admin action logged
🔒 **Rejections recorded** - data for model improvement

---

## 4️⃣ AI DISABLED MODE (V1 Runtime - Default)

```mermaid
sequenceDiagram
    actor Admin
    participant AdminWeb
    participant API
    participant AIService
    participant Config as Config<br/>Service

    Admin->>AdminWeb: Request Content Suggestion
    AdminWeb->>API: POST /suggestions (site_id=123)
    API->>Config: Check ai_enabled flag
    Config-->>API: ai_enabled = false
    API->>API: Short-circuit at API gate
    API-->>AdminWeb: Advisory not available
    AdminWeb-->>Admin: Graceful message

    Note over API,Config: No call to AI service
    Note over API,Config: No state mutation
    Note over API,Config: Zero latency cost
    Note over API,Config: Configuration-driven

    Admin->>AdminWeb: Enable AI
    AdminWeb->>API: POST /admin/config/ai_enabled=true
    API->>API: Validate admin authority (super-admin)
    API->>Config: Update flag
    Config-->>API: Updated
    API-->>AdminWeb: AI enabled

    Admin->>AdminWeb: Request Content Suggestion (retry)
    AdminWeb->>API: POST /suggestions
    API->>Config: Check ai_enabled flag
    Config-->>API: ai_enabled = true
    Note over API: Now proceeds to AI Service
```

### Graceful Degradation

🔒 **No external call when disabled** - configuration-driven short-circuit
🔒 **No state mutation** - zero impact on system
🔒 **Zero latency cost** - immediate API response
🔒 **Explicit message** - admin knows AI is disabled
🔒 **Runtime toggle** - can enable/disable without restart
🔒 **Suggested state cannot occur** - if disabled, Suggestion_Requested is impossible

---

## Authority Gates (Enforcement Points)

### Public Purchase Flow

1. **Entry Gate**: Visitor identity verified (anonymous/authenticated)
2. **Cart Gate**: Visitor can only modify own cart
3. **Checkout Gate**: Visitor must have valid shipping/billing
4. **Payment Gate**: Only validated webhook can confirm payment
5. **Confirmation Gate**: Only Commerce Engine can move to Confirmed

### AI Suggestion Flow

1. **Entry Gate**: Admin identity verified + role checked
2. **AI Gate**: ai_enabled flag checked
3. **Suggestion Gate**: Only AI service can create suggestions
4. **Approval Gate**: Only admin can approve (not AI)
5. **Publish Gate**: Approval creates version, doesn't overwrite canonical

### AI Disabled Gate

1. **Config Gate**: ai_enabled = false at API layer
2. **Short-circuit**: Request rejected before AI service touched
3. **Message Gate**: Graceful response with "Advisory Disabled"

---

## Key Invariants (Non-Negotiable)

✅ **No state is inferred** - only explicit transitions accepted
✅ **No authority leakage** - every action gated
✅ **No implicit approval** - admin action always required
✅ **No transaction loss** - atomic DB commits or full rollback
✅ **No ambiguous state** - state machine is exhaustive
✅ **No skipped validation** - all inputs validated
✅ **No silent failures** - all failures logged + alerted
✅ **No cross-tenant leakage** - site_id enforced at every layer

---

## Testing These Flows

### Happy Path Testing
- ✅ Verify cart persists across sessions
- ✅ Verify payment confirmation updates order state atomically
- ✅ Verify webhook signature validation rejects invalid signatures
- ✅ Verify site_id isolation (admin1 cannot see admin2's orders)

### Failure Path Testing
- ✅ Verify failed payment doesn't corrupt order
- ✅ Verify retry uses new idempotency key
- ✅ Verify 24h recovery window enforced
- ✅ Verify failure logs are immutable

### AI Path Testing
- ✅ Verify suggestion stored separately
- ✅ Verify canonical content unchanged until approval
- ✅ Verify approval creates new version
- ✅ Verify rejection is logged
- ✅ Verify site_id scopes suggestions
- ✅ Verify ai_enabled flag gates all AI calls
- ✅ Verify disable returns graceful message

### Authority Testing
- ✅ Verify visitor cannot confirm without payment
- ✅ Verify admin cannot override payment
- ✅ Verify AI cannot mutate order state
- ✅ Verify Integration layer cannot mutate state directly

---

**Runtime Sequences Version**: 1.0
**Status**: Foundation Phase
**Last Updated**: February 15, 2026
**Next Phase**: Level 4 - Component Protocols (API Contract Details - Request/Response Schemas)
