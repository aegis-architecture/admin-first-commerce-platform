# DATA DOMAIN IDENTIFICATION (STRICT)
Admin-First AI-Embedded Website & Commerce Platform

## Objective

Define what kinds of data exist and who owns them.

No ERD yet.
No attributes yet.
Just domains, ownership, mutation rights.

We design for ownership clarity before modeling.

## DOMAIN MAP (Authority-Aligned)

We define domains by responsibility boundaries — not by features.

## 1️⃣ Site & Identity Domain

**Purpose:**
Define tenant boundary and admin authority context.

**Owns:**
- Site
- DomainMapping
- AdminAccount
- AdminSiteMembership
- Role
- Permission
- RolePermission
- SiteConfiguration

**Can Change:**
- Domain mapping
- Site settings
- Role assignments

**Cannot Change:**
- Orders
- Payments
- Content state

**Dependencies:**
None (Root domain)

## 2️⃣ Content Domain

**Purpose:**
Manage structured public pages.

**Owns:**
- Page
- PageVersion
- SEO_Metadata
- MediaReference

**Can Change:**
- Content body
- Published version
- Metadata

**Cannot Change:**
- Orders
- Product pricing
- Payment state

**Dependencies:**
Requires Site Domain for scoping.

## 3️⃣ Product & Service Domain

**Purpose:**
Define commercial offerings.

**Owns:**
- Product
- ProductVersion
- InclusionDefinition
- ExclusionDefinition
- PricingDefinition

**Can Change:**
- Description
- Visibility
- Pricing

**Cannot Change:**
- Order lifecycle
- Payment confirmation

**Dependencies:**
Requires Site Domain.

## 4️⃣ Commerce Domain

**Purpose:**
Deterministic order lifecycle.

**Owns:**
- Cart
- Order
- OrderItem
- OrderStateTransitionLog

**Can Change:**
- Cart contents
- Order state

**Cannot Change:**
- Product canonical data
- Payment provider truth

**Dependencies:**
Product Domain (read-only)
Site Domain

## 5️⃣ Integration Domain

**Purpose:**
External system coordination.

**Owns:**
- PaymentConfiguration
- WebhookEventLog
- IntegrationCredentialReference
- EmailDispatchLog

**Can Change:**
- Gateway enable/disable
- Credential reference state

**Cannot Change:**
- Order state directly

**Dependencies:**
Commerce Domain (controlled access)
Site Domain

## 6️⃣ AI Advisory Domain

**Purpose:**
Admin assistance without authority mutation.

**Owns:**
- AISuggestion
- AISuggestionReview
- AIInteractionLog
- PromptTemplate

**Can Change:**
- Suggestion records only

**Cannot Change:**
- Canonical content
- Order state
- Pricing

**Dependencies:**
Content Domain (read-only)
Product Domain (read-only)
Site Domain

## 7️⃣ Audit Domain (Cross-Cutting but Owned)

**Purpose:**
Immutable trace of system behavior.

**Owns:**
- AdminActionLog
- SystemEventLog
- SecurityEventLog

**Can Change:**
- Append-only records

**Cannot Change:**
- Canonical domain data

**Dependencies:**
All domains (write-only, append model)

## DOMAIN RULES (Non-Negotiable)

- No shared ownership between domains.
- No circular domain dependency.
- Every entity must belong to exactly one domain.
- All canonical entities must include site_id.
- Cross-domain access must be explicit and read-only unless defined otherwise.

## VALIDATION CHECK

Any circular dependencies? → No

Any shared ownership? → No

Any ambiguous domain responsibility? → No

AI isolated? → Yes

Commerce deterministic? → Yes
