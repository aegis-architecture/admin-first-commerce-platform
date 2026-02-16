# LOW-FIDELITY WIREFRAMES
(Authority-Focused, Not Visual Design)

Admin-First AI-Embedded Website & Commerce Platform

## Objective:

Visualize decision surfaces
Highlight authority points
Highlight irreversible actions
Highlight uncertainty & failure states
Emphasize data visibility

No styling.
No branding.
Pure structure.

## 1️⃣ PUBLIC — PRODUCT DETAIL PAGE

### Wireframe Structure
```
---------------------------------------------------
[ NAVIGATION BAR ]

[ PRODUCT TITLE ]

[ SHORT DESCRIPTION ]

-----------------------------------------
[ DETAILED DESCRIPTION ]
-----------------------------------------

[ INCLUSIONS ]
[ EXCLUSIONS ]

-----------------------------------------
[ PRICE DISPLAY ]
-----------------------------------------

[ ADD TO CART BUTTON ]

-----------------------------------------
[ LEGAL LINKS ]
---------------------------------------------------
```

### Decision Surfaces

- Add to Cart (action trigger)
- Price display (read-only snapshot)
- Visibility dependent on Product.visibility

### Non-Negotiable UI Rules

- If Product.status != published → 404
- If visibility = hidden → Not renderable
- Price must reflect published ProductVersion only

## 2️⃣ PUBLIC — CHECKOUT PAGE

```
---------------------------------------------------
[ ORDER SUMMARY ]
  - Product
  - Quantity
  - Price Snapshot
  - Total

-----------------------------------------
[ CUSTOMER DETAILS FORM ]

-----------------------------------------
[ BILLING DETAILS FORM ]

-----------------------------------------
[ SUBMIT PAYMENT BUTTON ]

-----------------------------------------
[ PAYMENT STATUS MESSAGE AREA ]
---------------------------------------------------
```

### Authority Highlights

- Submit disabled during ProcessingPayment
- No editable pricing field
- No manual confirmation button

### Failure Surfaces

- Payment Failed banner
- Retry button
- Timeout message

## 3️⃣ ADMIN — DASHBOARD

```
---------------------------------------------------
[ SITE SWITCHER ]

[ ORDER SUMMARY PANEL ]
[ RECENT ACTIVITY PANEL ]

[ AI SUGGESTION QUEUE PANEL ] (if enabled)

[ ALERTS PANEL ]
---------------------------------------------------
```

### Authority Surfaces

- No direct state mutation
- Navigation-only surface
- Read-only summary

## 4️⃣ ADMIN — PAGE EDITOR

```
---------------------------------------------------
[ PAGE TITLE ]

[ VERSION STATUS BADGE ]

-----------------------------------------
[ CONTENT EDITOR AREA ]
-----------------------------------------

[ AI SUGGESTION PANEL ] (conditional)

-----------------------------------------
[ SAVE DRAFT ]
[ PUBLISH NEW VERSION ]
---------------------------------------------------
```

### Authority Points

- Publish = irreversible content state change
- Save Draft = reversible
- AI Suggestion = advisory only

### AI Panel Structure
```
[ REQUEST AI SUGGESTION ]

If generated:

[ SUGGESTION PREVIEW ]

[ APPROVE ]
[ REJECT ]
```

Approval creates new PageVersion.

## 5️⃣ ADMIN — PRODUCT EDITOR

```
---------------------------------------------------
[ PRODUCT TITLE ]

[ VISIBILITY TOGGLE ]

-----------------------------------------
[ DETAILED DESCRIPTION ]

[ INCLUSIONS ]
[ EXCLUSIONS ]

-----------------------------------------
[ PRICE FIELD ]

-----------------------------------------
[ SAVE DRAFT ]
[ PUBLISH VERSION ]
---------------------------------------------------
```

### Critical Constraints

If product referenced in confirmed order:
- Delete button hidden
- Archive allowed only

Publishing creates new ProductVersion.

## 6️⃣ ADMIN — ORDER DETAIL

```
---------------------------------------------------
[ ORDER NUMBER ]
[ CURRENT STATUS BADGE ]

-----------------------------------------
[ CUSTOMER DETAILS ]

-----------------------------------------
[ ORDER ITEMS LIST ]

-----------------------------------------
[ STATE TRANSITION HISTORY ]

-----------------------------------------
[ CANCEL ORDER BUTTON ] (conditional)
---------------------------------------------------
```

### Authority Points

- No manual confirm button
- Cancel visible only if allowed state
- Transition history immutable

## 7️⃣ ADMIN — INTEGRATION SETTINGS

```
---------------------------------------------------
[ PROVIDER SELECTOR ]

[ ENABLE TOGGLE ]

-----------------------------------------
[ CREDENTIAL INPUT FIELDS ]

-----------------------------------------
[ TEST CONFIGURATION BUTTON ]

-----------------------------------------
[ SAVE CONFIGURATION ]
---------------------------------------------------
```

### Authority Points

- Test must succeed before enabling
- Credentials never displayed in plain text
- Only one provider active per site

## 8️⃣ ADMIN — ROLE MANAGEMENT

```
---------------------------------------------------
[ ROLE LIST ]

-----------------------------------------
[ ROLE PERMISSION MATRIX ]

-----------------------------------------
[ ADMIN MEMBERSHIP LIST ]

[ INVITE ADMIN ]
---------------------------------------------------
```

### Authority Highlights

- Role scoped per site
- Permission matrix clearly visible
- No cross-site assignment possible

## 9️⃣ MULTI-SITE SWITCHER

```
[ ACTIVE SITE: Dropdown ▼ ]
```

### Switching:

- Forces reload
- Resets permissions
- Clears module state
- No mixed-site UI memory

## 🔟 GLOBAL FAILURE WIREFRAMES

### 403 Forbidden
```
[ ACCESS DENIED ]

You do not have permission to perform this action.
```

### AI Unavailable
```
[ AI SERVICE UNAVAILABLE ]

Retry Later.
```

### Payment Failed
```
[ PAYMENT FAILED ]

Reason: <error message>

[ RETRY PAYMENT ]
```

## WIREFRAME VALIDATION CHECK

✔ Irreversible actions visually distinct  
✔ No hidden authority action  
✔ All mutations explicit  
✔ All failure states visible  
✔ AI isolated in context  
✔ No cross-site UI blending  
✔ Role-based access reflected  
✔ Commerce states clear
