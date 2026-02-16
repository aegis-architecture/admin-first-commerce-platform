# END-TO-END TRACEABILITY (INVARIANT-VALIDATED)
Admin-First AI-Embedded Website & Commerce Platform

## Objective

Prove the system works as a whole by tracing:
- Authority transitions
- Data ownership boundaries
- Invariant enforcement
- Failure containment
- Tenant isolation

Every step must reference previously defined invariants.

If a flow can violate Phase 9 rules, the architecture fails.

## FLOW 1 — Visitor Purchase (Custom Domain, Happy Path)

### Context

Visitor accesses: https://brand.com

### Trace

#### Step 1 — Site Resolution

Host header received.
DomainMapping resolved.
site_id injected into request context.

**Invariant Enforced:**
✔ G1 — Tenant Isolation
✔ I1 — Unique Domain Mapping

**Failure Mode:**
If no mapping → 404.
No cross-site fallback allowed.

#### Step 2 — Cart Creation

Cart created with site_id.
Product lookup filtered by site_id.

**Invariant Enforced:**
✔ O4 — Order–Product Site Consistency
✔ G1 — Tenant Isolation

**Forbidden State Avoided:**
Cross-site product reference.

#### Step 3 — Checkout Initiation

Order created:
- status = pending_payment

OrderItem created with:
- product_version_id
- price_snapshot

**Invariant Enforced:**
✔ P2 — Price Snapshot Immutable
✔ O1 — Valid State Entry

#### Step 4 — Payment Request

Integration Orchestrator creates payment session.

**Invariant Enforced:**
✔ IN3 — Credential Scope Rule
✔ O4 — Site Consistency

#### Step 5 — Webhook Received

WebhookEventLog created.
Duplicate check:

✔ IN2 — Webhook Uniqueness
✔ O3 — Idempotency Rule

If duplicate → ignored.

#### Step 6 — Payment Validation

Signature verified.
If valid:
Commerce Engine transitions:
pending_payment → confirmed

Transition logged.

**Invariant Enforced:**
✔ O2 — Payment Confirmation Rule
✔ AU2 — Order Transition Logged

**Forbidden State Prevented:**
Confirmed without webhook.

## FLOW 2 — Payment Failure

Webhook status = failed.
Order transitions:
pending_payment → payment_failed

**Invariant Enforced:**
✔ O1 — Valid State Transition
✔ O3 — Idempotency

Order remains intact.
No partial confirmation.

## FLOW 3 — Admin Content Edit with AI Enabled

#### Step 1 — Authentication

Token validated.

**Invariant:**
✔ I4 — Permission Validation Gate

#### Step 2 — Site Resolution

site_id resolved via subdomain.

**Invariant:**
✔ G1 — Tenant Isolation

#### Step 3 — Permission Check

Permissions required:
- APPROVE_AI_SUGGESTIONS
- MANAGE_CONTENT

**Invariant:**
✔ I4 — Strict RBAC

If denied → 403.

#### Step 4 — AI Suggestion Creation

AISuggestion stored.

**Invariant:**
✔ A2 — Suggestion Scope Rule
✔ A4 — AI Toggle Enforcement

No mutation to Page table.

#### Step 5 — Suggestion Approval

New PageVersion created.

**Invariant:**
✔ C2 — Single Published Version
✔ C3 — Version Immutability
✔ AU1 — Admin Action Logged

AI cannot publish automatically.

## FLOW 4 — AI Disabled Mode

site_configuration.ai_enabled = false

AIController blocks suggestion request.

**Invariant:**
✔ A4 — AI Disabled Rule

System degrades gracefully.

## FLOW 5 — Cross-Site Access Attempt

Admin attempts:
GET /siteB/products

while authenticated for SiteA.

### Flow:

SiteResolver resolves siteB.
Membership check fails.

**Invariant:**
✔ I3 — Membership Uniqueness
✔ I4 — Permission Gate

**Result:**
403 Forbidden.

**Forbidden State Prevented:**
Cross-tenant data leakage.

## FLOW 6 — Product Referenced in Confirmed Order

Admin attempts to delete product.

System checks:
- Order exists referencing product.
- Order status = confirmed.

**Invariant:**
✔ Forbidden State #3
✔ O4 — Order–Product Site Consistency

**Result:**
Deletion blocked.
Product may be archived only.

## FAILURE CONTAINMENT VALIDATION

| Failure | Containment | Invariant |
|---------|-------------|-----------|
| Webhook replay | Ignored | O3 |
| Payment without signature | Rejected | O2 |
| AI hallucination | Suggestion only | A1 |
| Cross-site query | Blocked | G1 |
| Unauthorized admin action | 403 | I4 |
| Duplicate published version | Blocked | C2 |

No failure cascades across domains.

## TRACEABILITY PROOF

We now validate:

✔ Every flow references domain ownership  
✔ Every flow enforces tenant isolation  
✔ Every state transition logged  
✔ AI never mutates canonical data  
✔ RBAC enforced before controller execution  
✔ No domain mutates another domain directly  
✔ Append-only logs preserved  

No invariant violation possible without structural redesign.
