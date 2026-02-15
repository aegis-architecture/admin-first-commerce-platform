# C4 Level 2 - Container Model

**Architect Execution Framework — Phase 2**  
**AEGIS Layer 2 — Architecture & Design Layer**  
**System Decomposition: Deployable Runtime Units**

---

## Overview

The Admin-First Commerce Platform decomposes into seven distinct containers, each with single responsibility. Containers communicate through explicit interfaces with no implicit database sharing.

**Core Principle**: Each container is independently deployable and responsible for one domain.

---

## Container Responsibility Strategy

We divide by responsibility domains, not by technical layer:

```
Presentation Layer (Public)
│
├─ Public Web Application
└─ Admin Web Application

Application Layer
│
├─ Application API (Core Backend - Brain)
├─ Commerce Engine (Order Lifecycle)
└─ Integration Orchestrator (External Services)

Intelligence Layer
│
└─ AI Advisory Service (Toggleable - V1: Dormant)

Persistent Storage
│
└─ Primary Database (Authoritative Data)
```

---

## Container Definitions

### 1️⃣ PUBLIC WEB APPLICATION

**Technology**: Next.js / React (Frontend)

**Responsibility**:
- Render public website
- Display product/service catalog
- Manage shopping cart (client-side)
- Initiate checkout process
- Display order confirmation
- Handle visitor authentication (read-only)

**Cannot Do**:
- ✗ Mutate order state directly
- ✗ Execute payment logic
- ✗ Access AI provider directly
- ✗ Access admin functions
- ✗ Bypass API layer

**Communicates With**:
- Application API (REST/GraphQL)
- Payment Gateway (via API layer only)

**Data Access**:
- Read-only: Published products, published pages
- No direct database access

---

### 2️⃣ ADMIN WEB APPLICATION

**Technology**: Next.js / React (Frontend)

**Responsibility**:
- Content management interface
- Product/service CRUD
- Integration configuration UI
- Theme selection and customization
- Review AI suggestions (when enabled)
- View order history
- Manage admin users and roles

**Cannot Do**:
- ✗ Directly access database
- ✗ Directly call payment gateway
- ✗ Directly call AI provider
- ✗ Execute commerce logic
- ✗ Bypass approval workflows

**Communicates With**:
- Application API (REST/GraphQL)
- Authentication service

**Authentication**:
- 2FA capable
- Role-based access control (RBAC)
- Session timeout enforcement

---

### 3️⃣ APPLICATION API (Core Backend)

**Technology**: Node.js (Express/Fastify) or Python (FastAPI)

**Responsibility**:
- **Central orchestration layer** (The System Brain)
- API contract enforcement
- Authority rule enforcement
- State transition validation
- Request/response transformation
- Error handling and normalization
- Business rule validation
- Permission checking before delegating to specialized containers

**Cannot Do**:
- ✗ Direct payment processing
- ✗ Direct AI inference calls (except through AI Advisory Service)
- ✗ Database mutations without validation

**Communicates With**:
- Commerce Engine (for order operations)
- Integration Orchestrator (for external services)
- AI Advisory Service (if enabled)
- Primary Database (for queries/updates)
- Public Web Application
- Admin Web Application

**Critical Responsibility**:
This layer is the guardian of the boundary rules. All cross-boundary communication flows through here.

---

### 4️⃣ COMMERCE ENGINE

**Technology**: Deterministic state machine (Domain-Driven Design)

**Responsibility**:
- **Cart lifecycle management**
  - Add/remove items
  - Update quantities
  - Calculate totals with tax/shipping rules
  - Validate inventory

- **Order lifecycle management**
  - Create orders
  - Manage order states: Pending → Processing → Confirmed → Shipped → Delivered
  - Payment state coordination
  - Refund handling

- **Checkout validation**
  - Customer data validation
  - Inventory availability
  - Shipping address validation
  - Billing/shipping address match

- **Payment state handling** (CRITICAL)
  - Order may not complete without gateway authorization
  - Idempotency enforcement (same request = same result)
  - Payment state reconciliation

- **Invariant enforcement**
  - No negative inventory
  - No undefined order states
  - No payment without order context
  - No order completion without authorized payment

**Cannot Do**:
- ✗ Call external services directly
- ✗ Access AI
- ✗ Override approval workflows
- ✗ Modify commerce rules without explicit admin config

**Communicates With**:
- Application API (receives validated requests)
- Primary Database (persists order state)
- Integration Orchestrator (notifies of state changes)

---

### 5️⃣ INTEGRATION ORCHESTRATOR

**Technology**: Event-driven orchestrator (Webhooks, message queues)

**Responsibility**:
- **Payment gateway communication**
  - Send payment authorization requests (idempotent)
  - Receive and validate webhook signatures
  - Handle payment status updates
  - Retry logic with exponential backoff

- **Email dispatch**
  - Order confirmation emails
  - Contact form notifications
  - Admin alerts
  - Unsubscribe handling

- **Analytics integration** (future)
  - Event tracking
  - Performance metrics

- **Integration configuration validation**
  - Verify credentials
  - Test connectivity
  - Encrypt sensitive data

**Cannot Do**:
- ✗ Modify business logic
- ✗ Override order state without Commerce Engine
- ✗ Make autonomous decisions
- ✗ Call AI (reserved for AI Advisory Service)

**Communicates With**:
- Application API (receives dispatch requests)
- Commerce Engine (for state context)
- Primary Database (logs integration events)
- External: Payment Gateway, Email Provider, Analytics

**Failure Handling**:
- Failed integrations do NOT cascade to other services
- Admin notification on critical failures
- Retry queue for failed operations
- Manual intervention options

---

### 6️⃣ AI ADVISORY SERVICE

**Technology**: Toggleable service wrapper (LLM API calls)

**Status**: Disabled by default (V1)

**Responsibility** (When Enabled):
- Generate content suggestions
- Analyze content structure
- Provide readability metrics
- Flag ambiguous descriptions
- Suggest SEO improvements
- Format normalization recommendations
- Log all suggestions for audit

**Cannot Do** (Always Enforced):
- ✗ Publish changes automatically
- ✗ Modify commerce state
- ✗ Access payment data
- ✗ Directly write to database
- ✗ Make autonomous decisions
- ✗ Execute without approval

**Behavior When Disabled** (V1 Default):
```
if ai_enabled == false:
  - All endpoints return immediate no-op response
  - No external inference calls
  - No database writes
  - Zero latency impact
```

**Communicates With**:
- Application API (receives requests)
- AI Model Provider (LLM inference)
- Primary Database (logs suggestions only)

**Approval Workflow**:
```
1. AI generates suggestion
2. Suggestion logged with ID
3. Admin reviews via UI
4. Admin approves/rejects
5. If approved: Admin applies manually
6. All decisions logged for audit
```

---

### 7️⃣ PRIMARY DATABASE

**Technology**: PostgreSQL (or similar RDBMS)

**Purpose**:
- Persist canonical system data
- Enforce data integrity
- Support transactional consistency

**Owned By**:
- Application API (exclusive write access)
- Commerce Engine (via API layer only)

**Data Stored**:
- Users and admin roles
- Products/services
- Pages and content
- Orders and order items
- Payment records (tokenized, never raw PCI)
- Customer data
- Integration configurations (encrypted)
- AI suggestion logs
- Audit logs

**Access Pattern**:
- **No container accesses DB directly except backend**
- All queries go through Application API
- Transactions managed by backend
- Read replicas for analytics (future)

**Data Protection**:
- Encryption at rest
- Encryption in transit
- Row-level security where applicable
- Audit logging for all changes

---

## Container Interaction Patterns

### Pattern 1: Public User Checkout Flow

```
Public Web App
    ↓ (REST API)
Application API
    ↓ (validates request, enforces authority)
Commerce Engine
    ↓ (processes order)
Integration Orchestrator
    ↓ (calls Payment Gateway)
Payment Gateway (External)
    ↓ (webhook response)
Integration Orchestrator
    ↓ (notifies engine)
Commerce Engine
    ↓ (updates state)
Primary Database
    ↓ (transaction complete)
Public Web App (receives confirmation)
```

### Pattern 2: Admin Approves AI Suggestion

```
Admin Web App
    ↓ (REST API)
Application API
    ↓ (validates admin authority)
Primary Database
    ↓ (applies approved change)
AI Advisory Service
    ↓ (logs suggestion + admin action)
Primary Database (audit trail)
```

### Pattern 3: Admin Configuration Change

```
Admin Web App
    ↓ (REST API)
Application API
    ↓ (validates permissions)
Primary Database
    ↓ (persists configuration)
Integration Orchestrator
    ↓ (validates new config)
Internal test or External Service
    ↓ (confirms validity)
Application API
    ↓ (returns confirmation)
Admin Web App
```

---

## Communication Contracts

### API Gateway Responsibilities

- Rate limiting
- Request validation
- Authentication token verification
- Request/response logging
- Error normalization
- CORS handling

### Error Handling

```
Errors are scoped:

- Commerce Engine errors: Order-specific context
- Integration errors: Do not cascade
- AI errors: Graceful degradation
- Auth errors: Clear rejection
- Validation errors: Clear messaging
```

---

## Deployment Units

Each container is independently deployable:

```
- Public Web Application → Vercel / Netlify
- Admin Web Application → Vercel / Netlify
- Application API → Docker on ECS / Kubernetes
- Commerce Engine → Embedded in Application API
- Integration Orchestrator → Separate service / Sidekiq
- AI Advisory Service → Separate service / Lambda
- Primary Database → Managed database (RDS / Cloud SQL)
```

---

## Key Constraints (Non-Negotiable)

✅ **Single Responsibility**: Each container has one clear purpose
✅ **Explicit Communication**: No hidden orchestration
✅ **No Database Sharing**: Each container has defined data access
✅ **AI Isolation**: Always advisory, never autonomous
✅ **Commerce Determinism**: Payment flows are predictable
✅ **Authority Enforcement**: Admin control is enforced at API layer

---

**Container Model Version**: 2.0  
**Status**: Foundation Phase  
**Last Updated**: February 15, 2026  
**Next Phase**: Level 3 - Component Decomposition
