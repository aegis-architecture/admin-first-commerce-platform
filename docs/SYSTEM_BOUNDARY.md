
# System Boundary Definition (SBD)

**Architect Design Protocol § System Boundary**  
**AEGIS Layer 2 — Architecture & Design Layer**  
**Architect Execution Framework — Phase 1**

---

## 1️⃣ SYSTEM BOUNDARY STATEMENT

The system is a **single-tenant, admin-first website and commerce platform** that:

### IN SCOPE — System Owns & Controls

- **Public-facing brand experience** — Rendering, navigation, theming
- **Structured content management** — Pages, sections, media organization
- **Product/service catalog** — Data, descriptions, pricing structure
- **Deterministic commerce flows** — Cart, checkout, order state management
- **Payment gateway orchestration** — Integration, request/response handling
- **Admin advisory assistance** — AI suggestions (content, SEO, clarity)
- **Authority boundary enforcement** — Permission model, approval workflows
- **Data ownership** — Content, products, orders, configuration
- **Audit trail** — All admin actions and AI suggestions logged

### OUT OF SCOPE — System Does NOT Own

- **Payment processing logic** — Gateway performs authorization, capture, settlement
- **AI model weights** — Models owned/trained by external provider
- **Marketplace functionality** — Multi-vendor, commission logic, vendor onboarding
- **Mobile-native experiences** — Mobile app development; web-responsive only
- **Marketing automation** — Email campaigns, segmentation, behavioral flows
- **Raw API access for admins** — No direct database queries; structured endpoints only
- **Email infrastructure** — Delegated to notification provider
- **Hosting infrastructure** — Deployed on specified platform

---

## 2️⃣ PRIMARY ACTORS & CAPABILITIES

### Actor 1: ADMIN (Primary Authority Actor)

**Authority Level**: Full configuration within system boundaries

**Capabilities**:
- Configure content (pages, sections, navigation)
- Manage products/services (CRUD operations)
- Configure payment provider settings
- Configure integrations (email, analytics)
- **APPROVE** AI suggestions before publication
- Manage admin roles and permissions
- Switch themes and branding
- View order history and customer data
- Access audit logs

**Constraints** — Admin CANNOT:
- Modify core commerce logic
- Bypass payment validation flows
- Override irreversible state transitions
- Directly execute payment captures (gateway controls)
- Access raw AI model weights

### Actor 2: PUBLIC VISITOR (External User Actor)

**Authority Level**: None. Read-only + transaction initiation

**Capabilities**:
- Browse published content
- View product/service catalog
- Add items to cart
- Initiate checkout
- Submit contact forms
- View order confirmation (own orders only)

**Constraints**:
- Cannot configure system
- Cannot access admin functions
- Cannot view other users' data

### Actor 3: AI ADVISORY ENGINE (Advisory Actor)

**Authority Level**: NONE. Advisory-only. No autonomous actions.

**Capabilities**:
- Generate content improvement suggestions
- Flag ambiguity in product descriptions
- Propose SEO metadata enhancements
- Suggest content formatting improvements
- Assist with clarity assessment
- Log all suggestions with timestamps

**Constraints** — AI CANNOT:
- Mutate any commerce or content state
- Execute irreversible actions
- Publish content automatically
- Change prices, inventory, or navigation
- Bypass admin approval
- Access payment data
- Make autonomous decisions

### Actor 4: PAYMENT GATEWAY (External System)

**Examples**: Stripe, Paystack, Flutterwave (predefined integrations)

**Responsibilities**:
- Payment authorization validation
- Payment capture execution
- Refund processing
- Payment status reporting
- PCI-DSS compliance

**System Relationship**:
- System orchestrates gateway calls
- System does NOT control gateway internals
- Gateway is **final authority** on payment truth

---

## 3️⃣ DATA OWNERSHIP BOUNDARY

### Inside System — System is Authoritative

✓ Content Data (pages, sections, media)  
✓ Product Data (name, description, price)  
✓ Service Data (offerings, terms)  
✓ Order Data (items, quantities, state)  
✓ Integration Config (enabled providers, settings)  
✓ Navigation Structure (menu, URLs)  
✓ Theme Selection (active theme)  
✓ Audit Logs (all actions logged)  

### Outside System — External Authority

✗ Payment Authorization Truth (gateway owns)  
✗ AI Model Weights (provider owns)  
✗ Email Delivery Metadata (provider owns)  
✗ Hosting Infrastructure (platform owns)  
✗ DNS / Domain Registration (registrar owns)  
✗ SSL Certificates (certificate authority owns)  

### Critical Principle: Dual Authority Model

**Order State vs. Payment State** — MUST NOT CONFLICT

Order State Owner: System (Pending > Processing > Confirmed > Shipped > Delivered)  
Payment State Owner: Payment Gateway (Pending > Authorized > Captured > Failed > Refunded)  

**Invariant**: Order may not complete without gateway authorization. Gateway payment success does NOT guarantee order completion. Reconciliation via webhook is authoritative.

---

## 4️⃣ TRUST BOUNDARIES

We define four trust zones with explicit security requirements:

### TRUST ZONE A — Public Interface (Visitor ↔ Public Web)

**Risk Profile**: HIGH
- Input manipulation
- Fraud attempts
- Cart/price tampering
- CSRF attacks

**Controls**:
- Input validation (all fields)
- Rate limiting
- CSRF tokens
- Session timeout
- Bot detection

### TRUST ZONE B — Admin Interface (Admin ↔ Dashboard)

**Risk Profile**: CRITICAL
- Configuration misuse
- Credential compromise
- Unauthorized access

**Controls**:
- Authentication (password or SSO)
- Authorization (role-based)
- 2FA support
- Session timeout (15 min)
- Audit logging (all actions)
- IP whitelisting (optional)

### TRUST ZONE C — Commerce & Payment Boundary (System ↔ Gateway)

**Risk Profile**: CRITICAL
- Payment state inconsistency
- Double-charging
- Lost transactions

**Controls**:
- Idempotency keys (all requests)
- Signature validation (all webhooks)
- Explicit state transitions
- Nightly reconciliation
- Error handling with alerts
- Complete logging

### TRUST ZONE D — AI Advisory Boundary (System ↔ AI Provider)

**Risk Profile**: MEDIUM
- Hallucinated content
- Incorrect suggestions
- Service outage

**Controls**:
- No automatic mutation
- 5s timeout max
- Approval gates required
- Feature toggle
- No sensitive data access
- Graceful degradation

---

## 5️⃣ RESPONSIBILITY LIMITS

### System IS Responsible For:

✓ Rendering correct UI  
✓ Persisting structured data  
✓ Managing deterministic state machines  
✓ Enforcing invariants  
✓ Orchestrating external services  
✓ Validating user input  
✓ Maintaining audit logs  
✓ Securing configuration  
✓ Implementing approval workflows  

### System NOT Responsible For:

✗ Payment success guarantees (gateway failure = customer issue with bank)  
✗ AI model correctness (admin approves suggestions)  
✗ Email deliverability (provider responsibility)  
✗ Hosting uptime (infrastructure SLA)  
✗ Third-party API reliability (best-effort)  

---

## 6️⃣ SYSTEM INTEGRITY PRINCIPLES

### No Ambiguity
Every data item has exactly one owner.  
Every action has exactly one actor responsible.  
Every failure mode has explicit handling.  

### No Hidden Ownership
All data boundaries are explicit.  
All responsibility transfers documented.  
All authority handoffs logged.  

### No Implicit Responsibility
All workflows are explicit state machines.  
All system behavior is predictable.  
All edge cases handled explicitly.  

### No Authority Leakage
Admin cannot escape defined boundaries.  
AI cannot override approval gates.  
Public visitor cannot mutate system state.  
Gateway cannot control order state.  

---

**Document Status**: Foundation Phase (Phase 1)  
**Last Updated**: February 15, 2026  
**Next Review**: Architecture implementation checkpoint
