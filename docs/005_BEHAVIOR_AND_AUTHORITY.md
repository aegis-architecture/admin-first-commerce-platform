# PHASE 3 - BEHAVIOR & AUTHORITY MODELING

**Architect Execution Framework — Phase 3**
**AEGIS Layer 2 — Architecture & Design Layer**
**Behavioral Design: State Machines & Authority Chains**

---

## Overview

Phase 3 defines the runtime behavior of the system through deterministic state machines, explicit authority chains, and failure containment strategies. This layer ensures predictability, prevents unauthorized state transitions, and provides clear recovery paths.

---

## 1️⃣ ORDER LIFECYCLE (Deterministic State Machine)

### Order States

```
Draft
  ↓
Pending_Payment
  ↓ (webhook success)
Payment_Authorized
  ↓
Confirmed
  ↓
Fulfilled

(At any point before Confirmed)
Payment_Failed → Can retry Pending_Payment
Cancelled → Terminal state
```

### State Definitions

- **Draft**: Cart created, no payment attempt yet
- **Pending_Payment**: Payment request sent to gateway, awaiting response
- **Payment_Authorized**: Payment gateway confirmed authorization
- **Payment_Failed**: Payment gateway rejected authorization
- **Confirmed**: Order confirmed, ready for fulfillment
- **Fulfilled**: Order completed (if applicable)
- **Cancelled**: Order cancelled by admin or customer

### Core Principle: No State Inference

**Payment state is NOT inferred from other data.**

It is ONLY triggered by validated webhook from payment gateway:

```
Validation Rule:
1. Webhook signature verified
2. Idempotency key checked
3. Commerce Engine state updated
4. No partial transitions
5. All changes logged with timestamp
```

### Irreversible Transitions

✅ **Confirmed → Cannot return to Draft**
✅ **Fulfilled → Cannot revert to Confirmed**
✅ **Cancelled → Terminal state**

---

## 2️⃣ PAYMENT TRANSITION RULES

### Authority: Who Can Do What

**Only Commerce Engine may:**
- Transition Pending_Payment → Payment_Authorized
- Transition Pending_Payment → Payment_Failed
- Enforce idempotency

**Integration Orchestrator must:**
- Validate webhook signature
- Verify webhook came from authorized gateway
- Pass validated data to Commerce Engine
- NOT modify state directly

**Application API must:**
- Route payment webhook to Integration Orchestrator
- Enforce permission checks
- NOT bypass Commerce Engine

**AI has zero access here.**

### Payment Flow (Deterministic)

```
1. Public Web App
   ↓ (REST API: POST /orders/{id}/confirm)
2. Application API
   ↓ (validates authority)
3. Commerce Engine
   ↓ (validates order state)
4. Integration Orchestrator
   ↓ (sends idempotent request)
5. Payment Gateway (External)
   ↓ (processes payment)
6. Payment Gateway
   ↓ (sends webhook with signature)
7. Integration Orchestrator
   ↓ (validates signature, passes to Commerce Engine)
8. Commerce Engine
   ↓ (updates order state)
9. Primary Database
   ↓ (persists transaction)
10. Public Web App (receives confirmation)
```

---

## 3️⃣ AI ADVISORY WORKFLOW

### AI Suggestion States

```
Suggestion_Requested
  ↓
Suggestion_Generated
  ↓
Admin_Reviewing
  ↓ (admin approves)
Approved
  ↓ (creates new content version)
  ↓ (OR)
  ↓ (admin rejects)
Rejected → Logged

(At any state)
Expired → TTL exceeded
```

### Critical Rules

✅ **AI suggestion stored separately**
- Separate table from canonical content
- No impact on published content

✅ **Core content unchanged until approval**
- Admin explicitly approves each suggestion
- Approval creates new content version
- Old version preserved in history

✅ **Rejection logged**
- All rejections recorded with reason
- Used for AI model improvement

✅ **All AI activity auditable**
- Timestamp of suggestion
- Admin action recorded
- Audit trail immutable

✅ **AI cannot write directly to canonical content tables**
- No direct UPDATE access
- Suggestions are advisory only
- Admin approval required

---

## 4️⃣ TENANT ISOLATION ENFORCEMENT

### Every Request Must Include

- Authenticated Admin context (who is making the request)
- site_id resolution (which tenant)
- Permission matrix (what can they do)

### Enforcement Rules

**No cross-site joins**
- Queries must filter by site_id
- Database-level constraints enforced

**No shared order tables without site partition**
- Every order row includes site_id
- Foreign keys include site_id

**AI suggestions tagged by site_id**
- Suggestions only visible to their tenant
- Admin sees only own suggestions

**Payment configuration scoped by site_id**
- Each site can have different gateway
- Credentials encrypted per site

**Integration credentials scoped by site_id**
- Email provider, analytics, webhooks
- Per-tenant encryption
- No cross-tenant leakage

### Violation Response

**Violation of site boundary = architectural breach.**

```
If site_id mismatch detected:
1. Request immediately rejected
2. Error logged with context
3. Admin alert triggered
4. Investigation required
5. No data returned
```

---

## 5️⃣ FAILURE MODEL

We define failure zones, containment strategies, and blast radius for each critical system component.

### Payment Failure

**Failure Zone:** Payment Gateway Communication

**Containment Strategy:**
- Order remains in Pending_Payment or moves to Payment_Failed
- No partial order confirmation
- Idempotency keys prevent duplicate attempts
- Retry queue stores failed attempts

**Blast Radius:** Single order only
- Other orders unaffected
- No cascade to inventory
- No cascade to fulfillment

**Recovery Path:**
```
Admin Reviews Failed Payment:
1. See reason from gateway
2. Retry button available
3. Customer email sent
4. Order remains recoverable for 24h
5. After 24h, marked expired
```

### AI Failure

**Failure Zone:** AI Advisory Service

**Containment Strategy:**
- Suggestion request returns unavailable response
- UI shows "advisory disabled"
- No impact on content or commerce
- No database writes

**Blast Radius:** Admin UX only
- Public website unaffected
- Order processing unaffected
- Content management continues (without AI)

**Recovery Path:**
```
AI Service Down:
1. Integration Orchestrator detects timeout
2. Returns graceful error
3. Admin UI disabled advisory
4. Manual content management continues
5. AI comes online: suggestions resume
```

### Integration Failure

**Failure Zone:** Email provider or external service outage

**Containment Strategy:**
- Retry queue with exponential backoff
- No commerce logic rollback
- Order state preserved
- Failed integrations logged

**Blast Radius:** Notifications only
- Orders complete normally
- Payments authorized
- Fulfillment proceeds
- Admins notified of missing emails

**Recovery Path:**
```
Email Provider Down:
1. Integration Orchestrator detects failure
2. Adds to retry queue
3. Exponential backoff (1m, 5m, 15m, 60m)
4. After 24h, moves to dead letter queue
5. Admin can retry manually
```

### Database Failure

**Failure Zone:** Primary Database unavailable

**Containment Strategy:**
- All containers fail safe (read-only if possible)
- No partial state commits
- No background mutations
- Write operations return error

**Blast Radius:** Entire system
- Read-only mode if replicas available
- New orders rejected
- Public website may serve cached content
- Admins notified

**Recovery Path:**
```
Database Recovery:
1. DBA alerted automatically
2. Failover to replica (if configured)
3. Write operations resume
4. Pending requests retried (with TTL)
5. Audit log checked for consistency
```

---

## 6️⃣ AUTHORITY CHAIN

### Visitor (Public User)

**Can:**
- Create cart
- Add items to cart
- Remove items from cart
- View product catalog
- Initiate checkout

**Cannot:**
- ✗ Confirm order without payment
- ✗ Modify order state
- ✗ Access other visitors' carts
- ✗ View payment details

### Admin (Authenticated Operator)

**Can:**
- Configure content
- Create products/services
- View orders
- Refund orders
- Configure integrations
- Review AI suggestions
- Approve/reject AI suggestions

**Cannot:**
- ✗ Override payment authorization
- ✗ Create orders on behalf of visitors
- ✗ Modify payment state directly
- ✗ Bypass AI approval for content

### AI (Advisory System)

**Can:**
- Analyze content
- Generate suggestions
- Log suggestion activity
- Provide readability metrics
- Flag ambiguous descriptions

**Cannot:**
- ✗ Decide on anything
- ✗ Publish content
- ✗ Modify order state
- ✗ Access payment data
- ✗ Execute without approval
- ✗ Write to canonical tables

### Payment Gateway (External Authority)

**Can:**
- Authorize payment
- Reject payment
- Send webhooks
- Confirm amount

**Cannot:**
- ✗ Create orders independently
- ✗ Modify order state (only status)
- ✗ Access order data beyond payment context
- ✗ Decide fulfillment

### Commerce Engine (Internal Authority)

**Can (Final Authority):**
- Validate state transitions
- Enforce business rules
- Update order state
- Coordinate with Integration Orchestrator
- Enforce invariants

**Cannot:**
- ✗ Access payment data directly
- ✗ Call external services
- ✗ Modify AI suggestions
- ✗ Override admin decisions

---

## Key Constraints (Non-Negotiable)

✅ **Deterministic State Machines**: All state transitions are explicit and logged
✅ **No Implicit State**: Payment state only from webhook, never inferred
✅ **Authority Enforcement**: Each component has single responsibility
✅ **Failure Containment**: Failures isolated to their component
✅ **Audit Trail**: All critical transitions logged immutably
✅ **Tenant Isolation**: No cross-tenant data leakage
✅ **AI Advisory Only**: AI never makes decisions
✅ **Idempotency**: Same request always produces same result

---

**Behavior Model Version**: 1.0
**Status**: Foundation Phase
**Last Updated**: February 15, 2026
**Next Phase**: Level 4 - Component Protocols (Detailed API Contracts)
