# LOGICAL DATABASE SCHEMA
Admin-First AI-Embedded Website & Commerce Platform

## Objective:

Translate logical models into persistable structures while:
- Preserving domain ownership
- Preventing cross-domain corruption
- Enforcing tenant isolation
- Supporting future hard multi-site database isolation

No performance tuning.
No ORM assumptions.
No infrastructure choices.
Structure only.

## DATABASE STRATEGY (V1 Minimal, Future-Safe)

**V1:**
- Single database
- Shared schema
- Tenant-aware (site_id enforced everywhere)

**Future:**
- Schema-per-site OR
- Database-per-site

Design must support both without rewriting domain logic.

## SCHEMA ORGANIZATION (By Domain)

We logically group tables by domain (even if physically same DB).

## 1️⃣ SITE & IDENTITY SCHEMA

### Table: sites
| Column | Type (Logical) | Constraints |
|--------|----------------|-------------|
| site_id | UUID | PK |
| name | string | NOT NULL |
| status | enum | NOT NULL |
| created_at | timestamp | NOT NULL |
| updated_at | timestamp | NOT NULL |

### Table: domain_mappings
| Column | Type | Constraints |
|--------|------|-------------|
| mapping_id | UUID | PK |
| site_id | UUID | FK → sites |
| domain_name | string | UNIQUE |
| type | enum | NOT NULL |
| is_primary | boolean | |
| verification_status | enum | |
| is_active | boolean | |

### Table: admin_accounts
| Column | Type | Constraints |
|--------|------|-------------|
| admin_id | UUID | PK |
| email | string | UNIQUE |
| password_hash | string | NOT NULL |
| status | enum | NOT NULL |
| created_at | timestamp | |

### Table: roles
| Column | Type | Constraints |
|--------|------|-------------|
| role_id | UUID | PK |
| site_id | UUID | FK → sites |
| role_name | string | |
| description | string | |

UNIQUE (site_id, role_name)

### Table: permissions
| Column | Type | Constraints |
|--------|------|-------------|
| permission_key | string | PK |
| description | string | |

### Table: role_permissions
| Column | Type | Constraints |
|--------|------|-------------|
| role_id | UUID | FK → roles |
| permission_key | string | FK → permissions |

Composite PK (role_id, permission_key)

### Table: admin_site_memberships
| Column | Type | Constraints |
|--------|------|-------------|
| membership_id | UUID | PK |
| admin_id | UUID | FK → admin_accounts |
| site_id | UUID | FK → sites |
| role_id | UUID | FK → roles |
| status | enum | |

UNIQUE (admin_id, site_id)

## 2️⃣ CONTENT SCHEMA

### Table: pages
| Column | Type | Constraints |
|--------|------|-------------|
| page_id | UUID | PK |
| site_id | UUID | FK → sites |
| slug | string | |
| title | string | |
| status | enum | |
| created_at | timestamp | |

UNIQUE (site_id, slug)

### Table: page_versions
| Column | Type | Constraints |
|--------|------|-------------|
| version_id | UUID | PK |
| page_id | UUID | FK → pages |
| content_body | text | |
| version_number | integer | |
| created_by | UUID | FK → admin_accounts |
| is_published | boolean | |
| created_at | timestamp | |

UNIQUE (page_id, version_number)

### Table: seo_metadata
| Column | Type | Constraints |
|--------|------|-------------|
| metadata_id | UUID | PK |
| page_id | UUID | FK → pages |
| meta_title | string | |
| meta_description | string | |
| structured_data_json | json | |

## 3️⃣ PRODUCT SCHEMA

### Table: products
| Column | Type | Constraints |
|--------|------|-------------|
| product_id | UUID | PK |
| site_id | UUID | FK → sites |
| title | string | |
| short_description | string | |
| visibility | enum | |
| status | enum | |
| created_at | timestamp | |

### Table: product_versions
| Column | Type | Constraints |
|--------|------|-------------|
| version_id | UUID | PK |
| product_id | UUID | FK → products |
| detailed_description | text | |
| inclusion_details | text | |
| exclusion_details | text | |
| price_amount | decimal | |
| currency | string | |
| version_number | integer | |
| is_published | boolean | |
| created_at | timestamp | |

UNIQUE (product_id, version_number)

## 4️⃣ COMMERCE SCHEMA

### Table: carts
| Column | Type | Constraints |
|--------|------|-------------|
| cart_id | UUID | PK |
| site_id | UUID | FK → sites |
| session_identifier | string | |
| status | enum | |
| created_at | timestamp | |

### Table: orders
| Column | Type | Constraints |
|--------|------|-------------|
| order_id | UUID | PK |
| site_id | UUID | FK → sites |
| order_number | string | UNIQUE |
| status | enum | |
| total_amount | decimal | |
| currency | string | |
| customer_email | string | |
| created_at | timestamp | |
| updated_at | timestamp | |

### Table: order_items
| Column | Type | Constraints |
|--------|------|-------------|
| order_item_id | UUID | PK |
| order_id | UUID | FK → orders |
| product_id | UUID | |
| product_version_id | UUID | |
| quantity | integer | |
| price_snapshot | decimal | |
| currency | string | |

### Table: order_state_transition_logs
| Column | Type | Constraints |
|--------|------|-------------|
| transition_id | UUID | PK |
| order_id | UUID | FK → orders |
| from_state | enum | |
| to_state | enum | |
| triggered_by | enum | |
| timestamp | timestamp | |

Append-only enforced at application level.

## 5️⃣ INTEGRATION SCHEMA

### Table: payment_configurations
| Column | Type | Constraints |
|--------|------|-------------|
| config_id | UUID | PK |
| site_id | UUID | FK → sites |
| provider_name | string | |
| is_enabled | boolean | |
| credential_reference_id | UUID | |
| created_at | timestamp | |

### Table: integration_credential_references
| Column | Type | Constraints |
|--------|------|-------------|
| credential_reference_id | UUID | PK |
| site_id | UUID | FK → sites |
| encrypted_reference_key | string | |
| created_at | timestamp | |

### Table: webhook_event_logs
| Column | Type | Constraints |
|--------|------|-------------|
| webhook_event_id | UUID | PK |
| site_id | UUID | FK → sites |
| provider_name | string | |
| external_event_id | string | |
| payload_hash | string | |
| processed_status | enum | |
| received_at | timestamp | |

UNIQUE (provider_name, external_event_id)

### Table: email_dispatch_logs
| Column | Type | Constraints |
|--------|------|-------------|
| dispatch_id | UUID | PK |
| site_id | UUID | FK → sites |
| order_id | UUID | FK → orders |
| email_type | enum | |
| status | enum | |
| timestamp | timestamp | |

## 6️⃣ AI ADVISORY SCHEMA

### Table: ai_suggestions
| Column | Type | Constraints |
|--------|------|-------------|
| suggestion_id | UUID | PK |
| site_id | UUID | FK → sites |
| target_type | enum | |
| target_id | UUID | |
| suggestion_content | text | |
| status | enum | |
| created_at | timestamp | |

### Table: ai_suggestion_reviews
| Column | Type | Constraints |
|--------|------|-------------|
| review_id | UUID | PK |
| suggestion_id | UUID | FK → ai_suggestions |
| reviewed_by | UUID | FK → admin_accounts |
| decision | enum | |
| reviewed_at | timestamp | |

### Table: ai_interaction_logs
| Column | Type | Constraints |
|--------|------|-------------|
| interaction_id | UUID | PK |
| site_id | UUID | FK → sites |
| prompt_hash | string | |
| model_identifier | string | |
| token_usage | integer | |
| timestamp | timestamp | |

Append-only.

## TENANT ISOLATION GUARANTEE

All canonical tables include:
```
site_id NOT NULL
```

Future hard isolation possible by:
- Partition by site_id
- Move site-specific tables to dedicated schema
- Move entire site to dedicated database

No domain rewrite required.
