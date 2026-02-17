workspace {

    model {
        // ========== PEOPLE ==========
        
        admin = person "Admin" "Non-technical founder who configures website, products, payments, themes, and approves AI suggestions."

        visitor = person "Public Visitor" "End user who browses content and completes purchases."

        // ========== SYSTEM ==========
        
        platform = softwareSystem "Admin-First AI-Embedded Website & Commerce Platform" "Deterministic commerce system with embedded advisory AI layer. Provides content management, product/service management, payment orchestration, theme control, integration configuration, and AI-assisted admin guidance." {
            
            // ========== CONTAINERS ==========
            
            publicWeb = container "Public Web Application" "Render public website, display products/services, manage cart, initiate checkout" "React/Next.js" {
                tags "presentation,public"
            }

            adminWeb = container "Admin Web Application" "Manage content, products/services, integrations, themes, review AI suggestions" "React/Next.js" {
                tags "presentation,admin"
            }

            applicationApi = container "Application API" "Central orchestration layer, enforce authority rules, expose API contracts, enforce invariants" "Node.js/Express" {
                tags "backend,core"
                
                // === API COMPONENTS ===
                auth = component "Auth & Identity Resolver" "Handles authentication and identity verification" "Node.js/TypeScript" {
                    tags "component,auth"
                }
                siteResolver = component "Site Context Resolver" "Resolves site context and configuration" "Node.js/TypeScript" {
                    tags "component,context"
                }
                contentController = component "Content Controller" "Manages content operations" "Node.js/TypeScript" {
                    tags "component,content"
                }
                productController = component "Product Controller" "Manages product operations" "Node.js/TypeScript" {
                    tags "component,product"
                }
                orderController = component "Order Controller" "Manages order operations" "Node.js/TypeScript" {
                    tags "component,order"
                }
                integrationController = component "Integration Controller" "Manages integration operations" "Node.js/TypeScript" {
                    tags "component,integration"
                }
                aiController = component "AI Controller" "Manages AI advisory operations" "Node.js/TypeScript" {
                    tags "component,ai"
                }
                auditLogger = component "Audit Logger" "Logs system events and actions" "Node.js/TypeScript" {
                    tags "component,audit"
                }
                configManager = component "Configuration Manager" "Manages system configuration" "Node.js/TypeScript" {
                    tags "component,config"
                }
            }

            commerceEngine = container "Commerce Engine" "Cart logic, order lifecycle, checkout validation, payment state handling, idempotency enforcement" "Node.js/TypeScript" {
                tags "backend,commerce"
                
                // === COMMERCE COMPONENTS ===
                cartManager = component "Cart Manager" "Manages shopping cart operations" "Node.js/TypeScript" {
                    tags "component,cart"
                }
                orderLifecycle = component "Order Lifecycle Manager" "Manages order state transitions" "Node.js/TypeScript" {
                    tags "component,order"
                }
                paymentHandler = component "Payment State Handler" "Handles payment state transitions" "Node.js/TypeScript" {
                    tags "component,payment"
                }
                pricingValidator = component "Pricing Validator" "Validates pricing and discounts" "Node.js/TypeScript" {
                    tags "component,pricing"
                }
                idempotencyGuard = component "Idempotency Guard" "Ensures idempotent operations" "Node.js/TypeScript" {
                    tags "component,safety"
                }
            }

            integrationOrchestrator = container "Integration Orchestrator" "Payment gateway communication, webhook validation, email dispatch, integration configuration validation" "Node.js/TypeScript" {
                tags "backend,integration"
                
                // === INTEGRATION COMPONENTS ===
                paymentSession = component "Payment Session Manager" "Manages payment sessions" "Node.js/TypeScript" {
                    tags "component,integration,payment"
                }
                webhookValidator = component "Webhook Validator" "Validates incoming webhooks" "Node.js/TypeScript" {
                    tags "component,integration,webhook"
                }
                emailDispatcher = component "Email Dispatcher" "Sends email notifications" "Node.js/TypeScript" {
                    tags "component,integration,email"
                }
                credentialVault = component "Credential Vault Adapter" "Manages credential access" "Node.js/TypeScript" {
                    tags "component,integration,security"
                }
            }

            aiAdvisoryService = container "AI Advisory Service" "Generate advisory suggestions, analyze content structure, provide structured recommendations, log AI suggestions" "Node.js/TypeScript" {
                tags "backend,ai,optional"
                
                // === AI COMPONENTS ===
                aiToggle = component "AI Toggle Guard" "Enforces AI feature toggle" "Node.js/TypeScript" {
                    tags "component,ai,safety"
                }
                promptBuilder = component "Prompt Builder" "Constructs AI prompts" "Node.js/TypeScript" {
                    tags "component,ai,prompt"
                }
                inferenceClient = component "Inference Client" "Communicates with AI provider" "Node.js/TypeScript" {
                    tags "component,ai,client"
                }
                suggestionValidator = component "Suggestion Validator" "Validates AI suggestions" "Node.js/TypeScript" {
                    tags "component,ai,validation"
                }
                suggestionRepo = component "Suggestion Repository" "Persists AI suggestions" "Node.js/TypeScript" {
                    tags "component,ai,storage"
                }
                aiAudit = component "AI Audit Logger" "Logs AI operations" "Node.js/TypeScript" {
                    tags "component,ai,audit"
                }
            }

            primaryDatabase = container "Primary Database" "Persist canonical system data" "PostgreSQL" {
                tags "storage,database"
            }
        }

        // ========== EXTERNAL SYSTEMS ==========
        
        paymentGateway = softwareSystem "Payment Gateway" "Handles payment authorization, capture, and confirmation."

        emailProvider = softwareSystem "Email Provider" "Handles transactional email delivery such as order confirmations and inquiries."

        aiProvider = softwareSystem "AI Model Provider" "Executes language model inference for advisory content suggestions."

        // ========== RELATIONSHIPS ==========
        
        // People to System
        admin -> platform "Configures and manages system"
        visitor -> platform "Browses site and completes purchases"

        // People to Containers
        admin -> adminWeb "Manages content, products, integrations"
        visitor -> publicWeb "Browses and purchases"

        // Container Relationships - Following Architecture Rules
        publicWeb -> applicationApi "API calls for cart, checkout, content"
        adminWeb -> applicationApi "API calls for management operations"
        
        applicationApi -> commerceEngine "Delegates commerce operations"
        applicationApi -> integrationOrchestrator "Requests integrations"
        applicationApi -> aiAdvisoryService "Requests AI suggestions (optional)"
        applicationApi -> primaryDatabase "Persists data"
        
        commerceEngine -> integrationOrchestrator "Requests payment processing"
        commerceEngine -> applicationApi "Returns commerce results"
        
        integrationOrchestrator -> paymentGateway "Sends payment requests"
        integrationOrchestrator -> emailProvider "Sends notifications"
        integrationOrchestrator -> applicationApi "Returns integration results"
        
        aiAdvisoryService -> aiProvider "Requests inference when enabled"
        aiAdvisoryService -> applicationApi "Returns structured suggestions"

        // External System Relationships
        platform -> paymentGateway "Sends payment requests and validates webhooks"
        platform -> emailProvider "Sends transactional notifications"
        platform -> aiProvider "Requests advisory inference (AI toggle controlled)"

        // === COMPONENT RELATIONSHIPS ===
        
        // API Component Relationships
        orderController -> cartManager "Delegates cart ops"
        orderController -> orderLifecycle "Manages order state"
        integrationController -> paymentSession "Initiates payment"
        aiController -> aiToggle "Checks AI enabled"
        aiController -> promptBuilder "Builds prompt"
        
        // Commerce Component Relationships
        orderLifecycle -> paymentHandler "Handles payment transitions"
        orderLifecycle -> pricingValidator "Validates pricing"
        paymentHandler -> idempotencyGuard "Ensures safe retries"
        
        // AI Component Relationships
        promptBuilder -> inferenceClient "Calls model"
        inferenceClient -> suggestionValidator "Validates output"
        suggestionValidator -> suggestionRepo "Persists suggestion"
        suggestionRepo -> aiAudit "Logs suggestion events"
        
        // Integration Component Relationships
        webhookValidator -> paymentHandler "Passes validated events"
        emailDispatcher -> primaryDatabase "Reads order data for notifications"
    }

    views {

        systemContext platform {
            include *
            autolayout lr
        }

        container platform {
            include *
            autolayout tb
        }

        // === COMPONENT VIEWS ===
        component applicationApi {
            include *
            autolayout lr
        }

        component commerceEngine {
            include *
            autolayout lr
        }

        component aiAdvisoryService {
            include *
            autolayout lr
        }

        component integrationOrchestrator {
            include *
            autolayout lr
        }

        styles {
            element "Person" {
                background #08427B
                color #FFFFFF
            }
            element "Software System" {
                background #1168BD
                color #FFFFFF
            }
            element "External Software System" {
                background #999999
                color #FFFFFF
            }
            element "Container" {
                background #4A90E2
                color #FFFFFF
            }
            element "Database" {
                background #2E7D32
                color #FFFFFF
            }
            element "Component" {
                background #FF9800
                color #FFFFFF
            }
        }
    }
}
