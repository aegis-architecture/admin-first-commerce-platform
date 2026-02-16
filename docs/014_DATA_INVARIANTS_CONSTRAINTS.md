# DATA INVARIANTS & CONSTRAINTS
Admin-First AI-Embedded Website & Commerce Platform

## Objective:

Lock in non-negotiable truths of the system.

We now define:
- What must always be true
- What must never be true
- What constitutes an architectural breach
- What constitutes a recoverable bug

This is where the system becomes enforceable.

## 🔐 GLOBAL SYSTEM INVARIANTS

These apply across all domains.

### G1 — Tenant Isolation Invariant

Every canonical entity MUST:
- have site_id
- AND
- be accessed only via resolved site context

**Forbidden State:**
Any query that returns records across multiple site_ids without explicit platform-level authorization.

Architectural Breach.

### G2 — No Cross-Domain Mutation

A domain may not mutate another domain's canonical data.

**Examples:**
- AI domain cannot write to content tables.
- Integration domain cannot update order state directly.
- Content domain cannot modify pricing snapshots.

Violation = Architectural Breach.

### G3 — Append-Only Logs

The following tables must never allow update or delete:
- order_state_transition_logs
- webhook_event_logs
- ai_interaction_logs
- admin_action_logs

Violation = Architectural Breach.

### G4 — Site Deletion Safety

A Site cannot be deleted if:
- Orders exist
- Products exist
- Payment configurations exist

Must transition to "Archived" instead.

## 🧠 SITE & IDENTITY INVARIANTS

### I1 — Unique Domain Mapping

domain_name must be globally unique.

No two sites can share a domain.

### I2 — Role Scope Constraint

Role.site_id must equal AdminSiteMembership.site_id.

**Forbidden:**
Assigning a role from Site A to membership in Site B.

### I3 — Membership Uniqueness

(admin_id, site_id) must be unique.

An admin cannot have duplicate memberships for same site.

### I4 — Permission Validation Gate

No controller action executes without:
- Auth validation
- Membership validation
- Permission validation

If bypassed → Architectural Breach.

## 📄 CONTENT DOMAIN INVARIANTS

### C1 — Slug Uniqueness Per Site

(site_id, slug) must be unique.

### C2 — Single Published Version Rule

For each Page:
Only one PageVersion can have is_published = true.

Violation → Data Integrity Failure.

### C3 — Version Immutability

Once published, a PageVersion cannot be edited.

New version must be created.

## 🛒 PRODUCT DOMAIN INVARIANTS

### P1 — Single Published Product Version

Only one ProductVersion per Product may be published.

### P2 — Price Snapshot Rule

Price used in OrderItem must equal ProductVersion.price_amount at time of checkout.

After OrderItem creation:
price_snapshot must be immutable.

### P3 — Hidden Product Rule

If Product.visibility = hidden:
It cannot appear in listing queries.

## 💳 COMMERCE DOMAIN INVARIANTS

### O1 — Order State Validity

Order.status must follow defined state machine.

**Forbidden transitions:**
- confirmed → draft
- fulfilled → pending_payment
- cancelled → confirmed

### O2 — Payment Confirmation Rule

Order may transition to confirmed ONLY IF:
- Validated webhook exists
- Corresponding webhook_event_log exists
- Signature verification succeeded

### O3 — Idempotency Rule

Duplicate webhook events (same external_event_id) must not trigger duplicate state transitions.

### O4 — Order–Product Site Consistency

Order.site_id must equal:
- Product.site_id
- ProductVersion.site_id
- PaymentConfiguration.site_id

Violation → Architectural Breach.

## 🔌 INTEGRATION DOMAIN INVARIANTS

### IN1 — Single Active Payment Provider (Per Site)

At most one PaymentConfiguration may have is_enabled = true for a given provider type per site.

### IN2 — Webhook Uniqueness

(provider_name, external_event_id) must be unique.

Prevents replay corruption.

### IN3 — Credential Scope Rule

IntegrationCredentialReference.site_id must match PaymentConfiguration.site_id.

## 🤖 AI DOMAIN INVARIANTS

### A1 — Advisory Only Rule

AISuggestion.status may change, but:
- It must never directly mutate Page or Product tables.
- Only approval action in Content/Product domain may create new version.

### A2 — Suggestion Scope Rule

AISuggestion.site_id must equal target entity site_id.

### A3 — Suggestion Review Constraint

An AISuggestion cannot move to approved without:
- Existing AISuggestionReview record
- reviewed_by valid admin membership
- Permission APPROVE_AI_SUGGESTIONS

### A4 — AI Disabled Mode Rule

If site_configuration.ai_enabled = false:
No new AISuggestion records may be created.

## 🧾 AUDIT INVARIANTS

### AU1 — Every Admin Mutation Logged

Any action that changes canonical data must create:
AdminActionLog entry.

### AU2 — Order State Transition Logged

Every order status change must create:
OrderStateTransitionLog entry.

No silent transitions allowed.

## 🚨 FORBIDDEN SYSTEM STATES

These states must be structurally impossible:
- Order confirmed without validated webhook.
- AI suggestion applied without review.
- Product deleted while referenced in confirmed order.
- Page slug reused within same site.
- Admin accessing data from site without membership.
- Two published versions for same entity.
- Cross-tenant query execution.
- Integration webhook updating wrong site order.
- OrderItem price changed after creation.
- Role assigned across sites.

If any become possible → Architecture is invalid.

## DATA INTEGRITY CLASSIFICATION

| Type | Definition |
|------|------------|
| Bug | Application logic error recoverable without structural rewrite |
| Integrity Failure | Data violates invariant but can be corrected |
| Architectural Breach | System allows forbidden state structurally |

We design to eliminate Architectural Breaches.
