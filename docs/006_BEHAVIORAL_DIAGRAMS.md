# BEHAVIORAL DIAGRAMS - MERMAID VISUALIZATIONS

**Architect Execution Framework — Phase 3 Visualizations**
**AEGIS Layer 2 — Architecture & Design Layer**
**Visual Reference for State Machines & Authority Chains**

---

## 1️⃣ ORDER LIFECYCLE STATE MACHINE

```mermaid
stateDiagram-v2
    [*] --> Draft: New Order
    Draft --> Pending_Payment: Checkout Initiated
    Pending_Payment --> Payment_Authorized: ✅ Webhook Valid
    Pending_Payment --> Payment_Failed: ❌ Gateway Reject
    Payment_Failed --> Pending_Payment: Retry (Admin/Customer)
    Payment_Authorized --> Confirmed: Order Confirmed
    Confirmed --> Fulfilled: Shipped/Delivered
    Confirmed --> Cancelled: Admin Cancel
    Payment_Failed --> Cancelled: Abandon (24h TTL)
    Fulfilled --> [*]
    Cancelled --> [*]
    
    note right of Pending_Payment
        Only Commerce Engine
        can transition states.
        Webhook signature MUST
        be validated first.
    end note
    
    note right of Confirmed
        Irreversible Transition:
        Cannot return to Draft
        Cannot return to Pending_Payment
    end note
```

### Rules

🔒 **Only Commerce Engine transitions states**
🔒 **Webhook must be validated before state mutation**
🔒 **No AI involvement in payment state**
🔒 **No direct admin override of payment authorization**
🔒 **Idempotency enforced on all transitions**

---

## 2️⃣ AI ADVISORY APPROVAL WORKFLOW

```mermaid
stateDiagram-v2
    [*] --> Suggestion_Requested: Admin Requests
    Suggestion_Requested --> Suggestion_Generated: AI Analyzes
    Suggestion_Generated --> Admin_Reviewing: Suggestion Ready
    Admin_Reviewing --> Approved: Admin Approves
    Admin_Reviewing --> Rejected: Admin Rejects
    Approved --> [*]: Content Version Created
    Rejected --> [*]: Logged for Audit
    
    note right of Suggestion_Generated
        AI suggestion stored
        in separate table.
        Canonical content
        NOT modified.
    end note
    
    note right of Admin_Reviewing
        Admin can:
        - Review suggestion
        - Approve (creates version)
        - Reject (logged)
        
        Suggestions tagged
        by site_id for
        tenant isolation.
    end note
```

### Rules

🔒 **Canonical content untouched until Approved**
🔒 **All suggestions tagged by site_id**
🔒 **Full audit trail required**
🔒 **If AI disabled → Requested state cannot occur**
🔒 **AI cannot write directly to canonical tables**

---

## 3️⃣ AUTHORITY CHAIN DIAGRAM

```mermaid
graph TD
    V["👤 Visitor<br/>(Public User)"]
    A["👨‍💼 Admin<br/>(Authenticated)"]
    AI["🤖 AI Advisory<br/>(Toggleable)"]
    CE["⚙️ Commerce Engine<br/>(Deterministic Brain)"]
    IO["🔌 Integration<br/>Orchestrator"]
    DB[("🗄️ Primary<br/>Database")]
    PG["💳 Payment<br/>Gateway<br/>(External)"]
    
    V -->|"Can: Create cart<br/>Add/Remove items"| CE
    V -->|"Cannot: Confirm<br/>without payment"| CE
    
    A -->|"Can: Configure<br/>View orders<br/>Approve AI"| CE
    A -->|"Cannot: Override<br/>payment auth"| CE
    
    AI -->|"Can: Suggest<br/>Analyze content"| A
    AI -->|"Cannot: Decide<br/>Publish<br/>Modify orders"| CE
    
    CE -->|"Authority:<br/>Validate state<br/>Enforce rules"| DB
    CE -->|"Can call<br/>validated webhooks"| IO
    CE -->|"Cannot call<br/>payment gateway<br/>directly"| IO
    
    IO -->|"Can: Route<br/>webhooks<br/>Send email"| CE
    IO -->|"Cannot: Mutate<br/>order state"| CE
    
    IO -->|"External<br/>Integration"| PG
    
    style V fill:#e1f5ff
    style A fill:#fff3e0
    style AI fill:#f3e5f5
    style CE fill:#e8f5e9
    style IO fill:#fce4ec
    style DB fill:#ede7f6
    style PG fill:#ffccbc
```

### Enforcement

🔒 **AIService cannot call CommerceEngine directly**
🔒 **IntegrationOrchestrator cannot mutate order state**
🔒 **Database writes only through controlled containers**
🔒 **Payment Gateway cannot create orders independently**
🔒 **Visitor cannot confirm order without payment**

---

## 4️⃣ TENANT ISOLATION BOUNDARY

```mermaid
graph TD
    R["Request with<br/>site_id + auth"]
    
    R -->|site_id: 123| S1["TENANT 1<br/>site_id: 123"]
    R -->|site_id: 456| S2["TENANT 2<br/>site_id: 456"]
    
    S1 -->|"Orders<br/>(site_id=123)"| DB1[("DB Partition<br/>Tenant 1")]
    S1 -->|"Products<br/>(site_id=123)"| DB1
    S1 -->|"Integrations<br/>(site_id=123)"| DB1
    S1 -->|"AI Suggestions<br/>(site_id=123)"| DB1
    
    S2 -->|"Orders<br/>(site_id=456)"| DB2[("DB Partition<br/>Tenant 2")]
    S2 -->|"Products<br/>(site_id=456)"| DB2
    S2 -->|"Integrations<br/>(site_id=456)"| DB2
    S2 -->|"AI Suggestions<br/>(site_id=456)"| DB2
    
    VIO["Violation:<br/>site_id mismatch"]
    VIO -->|"❌ Request Rejected<br/>❌ Alert Triggered<br/>❌ Logged"| LOG["Audit Log"]
    
    R -.->|"Invalid attempt"| VIO
    
    style S1 fill:#c8e6c9
    style S2 fill:#bbdefb
    style DB1 fill:#a5d6a7
    style DB2 fill:#64b5f6
    style VIO fill:#ffcdd2
    style LOG fill:#ffe0b2
```

### Critical Principle

🔒 **Every entity must include site_id**
🔒 **No cross-site query allowed**
🔒 **Database-level constraints enforced**
🔒 **Future database-per-site migration requires zero domain rewrite**
🔒 **Violation = immediate architectural breach alert**

---

## 5️⃣ FAILURE CONTAINMENT MAP

```mermaid
graph TD
    PF["💳 PAYMENT FAILURE<br/>Zone: Payment Gateway"]
    PF -->|"Blast Radius:"| PF_BR["Single Order Only<br/>No cascade"]
    PF -->|"Containment:"| PF_CONT["Retry Queue<br/>Idempotency Keys<br/>24h Recovery"]
    PF -->|"State:"| PF_STATE["Pending_Payment<br/>OR<br/>Payment_Failed"]
    
    AF["🤖 AI FAILURE<br/>Zone: AI Advisory Service"]
    AF -->|"Blast Radius:"| AF_BR["Admin UX Only<br/>Zero Impact"]
    AF -->|"Containment:"| AF_CONT["Returns unavailable<br/>UI disables advisory<br/>No DB writes"]
    AF -->|"State:"| AF_STATE["Content unaffected<br/>Commerce proceeds"]
    
    IF["📧 INTEGRATION FAILURE<br/>Zone: External Services"]
    IF -->|"Blast Radius:"| IF_BR["Notifications Only<br/>Commerce Proceeds"]
    IF -->|"Containment:"| IF_CONT["Retry Queue<br/>Exponential Backoff<br/>Dead Letter Queue"]
    IF -->|"State:"| IF_STATE["Order completes<br/>Payment authorized<br/>Fulfillment proceeds"]
    
    DBF["🗄️ DATABASE FAILURE<br/>Zone: Primary Database"]
    DBF -->|"Blast Radius:"| DBF_BR["Entire System<br/>Fail-Safe Mode"]
    DBF -->|"Containment:"| DBF_CONT["Read-only mode<br/>No partial commits<br/>Failover to replica"]
    DBF -->|"State:"| DBF_STATE["New writes blocked<br/>Public cached<br/>Admins notified"]
    
    style PF fill:#ffcdd2
    style PF_BR fill:#ef9a9a
    style PF_CONT fill:#e57373
    style PF_STATE fill:#c62828
    
    style AF fill:#f3e5f5
    style AF_BR fill:#e1bee7
    style AF_CONT fill:#ce93d8
    style AF_STATE fill:#7b1fa2
    
    style IF fill:#fff9c4
    style IF_BR fill:#ffe082
    style IF_CONT fill:#ffd54f
    style IF_STATE fill:#f9a825
    
    style DBF fill:#cfd8dc
    style DBF_BR fill:#b0bec5
    style DBF_CONT fill:#90a4ae
    style DBF_STATE fill:#37474f
```

### Principles

🔒 **Each failure has bounded blast radius**
🔒 **Does not corrupt canonical state**
🔒 **Does not cascade uncontrollably**
🔒 **Clear recovery paths defined**
🔒 **Admin notification on critical failures**

---

## 6️⃣ PAYMENT FLOW WITH VALIDATION

```mermaid
sequenceDiagram
    participant V as Public Web App
    participant API as Application API
    participant CE as Commerce Engine
    participant IO as Integration Orchestrator
    participant PG as Payment Gateway
    participant DB as Database
    
    V->>API: POST /orders/{id}/confirm
    API->>API: Validate authority + permissions
    API->>CE: Request state transition
    CE->>CE: Validate Pending_Payment → Payment_Authorized
    CE->>IO: Send idempotent payment request
    IO->>PG: POST /authorize (idempotency-key)
    PG-->>IO: Response (success/fail)
    IO->>IO: Validate webhook signature
    IO->>CE: Deliver validated result
    CE->>DB: Update order state + timestamp
    DB-->>CE: Confirmed
    CE-->>API: State changed
    API-->>V: Order confirmation
    
    Note over PG,CE: Webhook must be signed<br/>Idempotency enforced
    Note over CE,DB: Atomic transaction<br/>No partial state
```

---

## 7️⃣ TENANT ISOLATION IN REQUEST FLOW

```mermaid
sequenceDiagram
    participant Admin as Admin User
    participant Auth as Auth Service
    participant API as Application API
    participant CE as Commerce Engine
    participant DB as Database
    
    Admin->>Auth: Authenticate
    Auth-->>Auth: Resolve site_id
    Auth-->>Admin: Token + site_id
    Admin->>API: GET /orders (with token)
    API->>API: Extract site_id from token
    API->>CE: GET orders WHERE site_id=123
    CE->>DB: Query with site_id filter
    DB-->>CE: Only orders for site 123
    CE-->>API: Filtered results
    API-->>Admin: Results for tenant 123
    
    Note over API,CE: Every query includes<br/>site_id constraint
    Note over DB: Database enforces<br/>site_id in all keys
```

---

## Key Diagram Principles

### State Machines
- ✅ All states explicitly defined
- ✅ Transitions deterministic
- ✅ No implicit state inference
- ✅ Invalid transitions rejected

### Authority Chains
- ✅ Clear component boundaries
- ✅ Single responsibility per component
- ✅ No authority leakage
- ✅ Explicit permission checks

### Tenant Isolation
- ✅ site_id on all entities
- ✅ Database-level enforcement
- ✅ Request-level validation
- ✅ Violation detection + alerting

### Failure Containment
- ✅ Bounded blast radius
- ✅ No cascade failures
- ✅ Canonical state protected
- ✅ Clear recovery paths

---

**Diagrams Version**: 1.0
**Mermaid Version**: 10+
**Status**: Foundation Phase
**Last Updated**: February 15, 2026
**Next Phase**: Level 4 - Component Protocols (API Contract Details)
