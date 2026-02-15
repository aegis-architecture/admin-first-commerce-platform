# C4 LEVEL 3 - COMPONENT MODEL

**Architect Execution Framework — Phase 4**
**AEGIS Layer 2 — Architecture & Design Layer**
**Internal Component Decomposition: Domain Logic & Responsibilities**

---

## Overview

Level 3 refines the containers into internal components. Each component represents a logical bundle of functionality with a single responsibility. This layer defines how domain logic is organized within the runtime units.

---

## 1️⃣ APPLICATION API - COMPONENTS

**Container**: Application API (Core Backend)
**Responsibilities**: Route requests, enforce authority, resolve site context, validate invariants.

### Components

- **Auth & Identity Resolver**: Handles JWT validation, session management, and RBAC resolution.
- **Site Context Resolver**: Resolves `site_id` from headers/tokens and enforces tenant isolation at the request entry point.
- **Content Controller**: Orchestrates CMS operations, versioning, and approval workflows.
- **Product Controller**: Manages product/service catalog CRUD and visibility rules.
- **Order Controller**: Orchestrates order creation and delegates state management to the Commerce Engine.
- **Integration Controller**: Manages configuration and dispatch requests for external services.
- **AI Controller**: Interface for AI advisory requests; enforces feature toggles and approval gates.
- **Audit Logger**: Independent component for recording all critical system events and authority changes.
- **Configuration Manager**: Manages system and tenant-level settings (e.g., `ai_enabled` flag).

---

## 2️⃣ COMMERCE ENGINE - COMPONENTS

**Container**: Commerce Engine (Deterministic Brain)
**Responsibilities**: Order lifecycle, cart validation, payment state transitions, idempotency.

### Components

- **Cart Manager**: Manages cart persistence, item validation, and quantity limits.
- **Order Lifecycle Manager**: Deterministic state machine enforcing order state transitions.
- **Payment State Handler**: Exclusively handles transitions related to payment status (Authorized, Failed).
- **Pricing Validator**: Ensures total calculation accuracy, tax application, and shipping rules.
- **Idempotency Guard**: Ensures that duplicate payment/order requests do not result in duplicate state changes.

---

## 3️⃣ AI ADVISORY SERVICE - COMPONENTS

**Container**: AI Advisory Service (Toggleable Intelligence)
**Responsibilities**: Prompt construction, suggestion validation, persistence, audit logging.

### Components

- **AI Toggle Guard**: Non-negotiable gatekeeper that checks system/tenant-level AI status before any operation.
- **Prompt Builder**: Constructs safe, context-aware prompts for the LLM based on system domain rules.
- **Inference Client**: Handles communication with external AI Model Providers (e.g., OpenAI, Anthropic).
- **Suggestion Validator**: Validates AI output against system constraints before presenting to Admin.
- **Suggestion Repository**: Manages storage and retrieval of AI suggestions (isolated from canonical tables).
- **AI Audit Logger**: Records every prompt generated, response received, and admin decision made.

---

## 4️⃣ INTEGRATION ORCHESTRATOR - COMPONENTS

**Container**: Integration Orchestrator (External Bridge)
**Responsibilities**: Payment sessions, webhook validation, email dispatch, credential security.

### Components

- **Payment Session Manager**: Creates and manages sessions with external payment gateways (e.g., Stripe, PayPal).
- **Webhook Validator**: Validates cryptographic signatures of incoming webhooks from external providers.
- **Email Dispatcher**: Orchestrates transactional email delivery via providers (e.g., SendGrid, Postmark).
- **Credential Vault Adapter**: Securely retrieves encrypted tenant credentials for external service access.

---

## STRUCTURIZR DSL - COMPONENT MODEL

```structurizr
workspace {
    model {
        admin = person \"Admin\"
        visitor = person \"Public Visitor\"
        platform = softwareSystem \"Admin-First AI-Embedded Website & Commerce Platform\"

        api = container platform \"Application API\"
        commerce = container platform \"Commerce Engine\"
        integration = container platform \"Integration Orchestrator\"
        aiService = container platform \"AI Advisory Service\"
        database = container platform \"Primary Database\"

        // === API COMPONENTS ===
        auth = component api \"Auth & Identity Resolver\"
        siteResolver = component api \"Site Context Resolver\"
        contentController = component api \"Content Controller\"
        productController = component api \"Product Controller\"
        orderController = component api \"Order Controller\"
        integrationController = component api \"Integration Controller\"
        aiController = component api \"AI Controller\"
        auditLogger = component api \"Audit Logger\"
        configManager = component api \"Configuration Manager\"

        // === COMMERCE COMPONENTS ===
        cartManager = component commerce \"Cart Manager\"
        orderLifecycle = component commerce \"Order Lifecycle Manager\"
        paymentHandler = component commerce \"Payment State Handler\"
        pricingValidator = component commerce \"Pricing Validator\"
        idempotencyGuard = component commerce \"Idempotency Guard\"

        // === AI COMPONENTS ===
        aiToggle = component aiService \"AI Toggle Guard\"
        promptBuilder = component aiService \"Prompt Builder\"
        inferenceClient = component aiService \"Inference Client\"
        suggestionValidator = component aiService \"Suggestion Validator\"
        suggestionRepo = component aiService \"Suggestion Repository\"
        aiAudit = component aiService \"AI Audit Logger\"

        // === INTEGRATION COMPONENTS ===
        paymentSession = component integration \"Payment Session Manager\"
        webhookValidator = component integration \"Webhook Validator\"
        emailDispatcher = component integration \"Email Dispatcher\"
        credentialVault = component integration \"Credential Vault Adapter\"

        // === KEY RELATIONSHIPS ===
        orderController -> cartManager \"Delegates cart ops\"
        orderController -> orderLifecycle \"Manages order state\"
        orderLifecycle -> paymentHandler \"Handles payment transitions\"
        orderLifecycle -> pricingValidator \"Validates pricing\"
        paymentHandler -> idempotencyGuard \"Ensures safe retries\"

        aiController -> aiToggle \"Checks AI enabled\"
        aiController -> promptBuilder \"Builds prompt\"
        promptBuilder -> inferenceClient \"Calls model\"
        inferenceClient -> suggestionValidator \"Validates output\"
        suggestionValidator -> suggestionRepo \"Persists suggestion\"
        suggestionRepo -> aiAudit \"Logs suggestion events\"

        integrationController -> paymentSession \"Initiates payment\"
        webhookValidator -> paymentHandler \"Passes validated events\"
        emailDispatcher -> database \"Reads order data for notifications\"
    }

    views {
        component api {
            include *
            autolayout lr
        }
        component commerce {
            include *
            autolayout lr
        }
        component aiService {
            include *
            autolayout lr
        }
        component integration {
            include *
            autolayout lr
        }
    }
}
```

---

## STRUCTURAL GUARANTEES ACHIEVED

✅ **AI toggle enforced** before any inference occurs.
✅ **Commerce isolated** from AI logic.
✅ **Webhook validation** ensures no unauthorized state mutation.
✅ **Idempotency guard** enforced at the state handler level.
✅ **Site resolution** separated from business controllers.
✅ **Audit logging** decoupled from domain logic.
✅ **Credential vault** access strictly via adapter.
✅ **Single Responsibility**: No component has more than one reason to change.

---

**Component Model Version**: 1.0
**Status**: Foundation Phase
**Last Updated**: February 15, 2026
**Next Phase**: Level 4 - Component Protocols (Detailed API Contracts & Schemas)
