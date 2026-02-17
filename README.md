# ACME Corp - Terraform Cloud Governance Demo

**Author:** Chase Erickson  
**Organization:** HashiCorp, an IBM Company

---

## Overview

This repository demonstrates how **Terraform Cloud** addresses infrastructure governance challenges at scale through workspace isolation, policy enforcement, and centralized state management.

**Business Context:**

ACME Corp is a global e-commerce company experiencing rapid growth. Their infrastructure challenges include:
- Teams using inconsistent deployment methods (AWS Console, local Terraform, manual processes)
- Production incidents from infrastructure misconfigurations
- Limited visibility into deployed resources and change history
- Manual review processes creating deployment bottlenecks

**Solution:**

Terraform Cloud provides:
- **Workspace isolation** - Teams work independently without state conflicts
- **Automated policy enforcement** - Mistakes caught at plan time, before deployment
- **Centralized state management** - Complete visibility and audit trail
- **Standardized workflows** - Consistent processes across all teams

---

## Repository Structure
```
acme-corp-tfc-demo/
├── storefront/
│   └── prod/
│       └── main.tf          # Mature team - all policies passing
├── checkout/
│   └── prod/
│       └── main.tf          # Fast-moving team - encryption violation
├── data-platform/
│   └── prod/
│       └── main.tf          # New team - multiple violations
├── policies/
│   ├── sentinel.hcl         # Policy set configuration
│   ├── s3-encryption.sentinel
│   ├── required-tags.sentinel
│   └── cost-threshold.sentinel
└── README.md
```

---

## Workspace Scenarios

Each workspace represents a different team at ACME Corp with varying infrastructure maturity levels.

### Workspace 1: `storefront` 

**Team:** Storefront Engineering (Product Catalog & Web Assets)  
**Infrastructure Maturity:** High  
**Policy Status:** ✅ All passing

**Resources:**
- Product catalog S3 bucket (encrypted, properly tagged)
- Static assets S3 bucket (encrypted, properly tagged)
- Web server EC2 instance (t3.small, ~$15/month)

**Purpose:** Demonstrates best practices and the target state for all teams.

---

### Workspace 2: `checkout`

**Team:** Checkout & Payments Engineering  
**Infrastructure Maturity:** Medium  
**Policy Status:** ❌ Hard fail - S3 encryption violation

**Resources:**
- Customer order data S3 bucket (**missing encryption**)
- Payment audit logs S3 bucket (encrypted ✅)
- Checkout API EC2 instance (t3.medium, ~$30/month)

**Violation Scenario:**  
Developer copy-pasted an S3 bucket configuration under deadline pressure and omitted the encryption block. Represents a common, realistic mistake on fast-moving teams.

**Without TFC policies:** Unencrypted customer order data reaches production  
**With TFC policies:** Deployment blocked at plan time, fixed in minutes

---

### Workspace 3: `data-platform`

**Team:** Data & Analytics Engineering (3 months old)  
**Infrastructure Maturity:** Low  
**Policy Status:** ❌ Multiple hard fails

**Resources:**
- Customer behavior data S3 bucket (**no encryption, no tags**)
- Data processing EC2 instance (r5.2xlarge, **~$500/month**)
- Analytics RDS database (db.r5.xlarge, **unencrypted, no tags, ~$400/month**)

**Violations:**
- S3 bucket missing server-side encryption
- S3 bucket missing required tags (Environment, Team, CostCenter, Owner, ManagedBy)
- EC2 instance exceeds cost threshold ($200/month limit)
- RDS storage encryption disabled
- RDS instance missing required tags
- RDS instance exceeds cost threshold

**Total Est. Monthly Cost:** ~$900/month

**Violation Scenario:**  
New team of data scientists unfamiliar with cloud governance copied a basic example to get started quickly. Multiple security and cost violations present.

**Without TFC policies:** $900/month surprise bill + customer data unencrypted  
**With TFC policies:** All violations caught before any infrastructure is provisioned

---

## Policy Enforcement

### S3 Encryption Policy

**File:** `policies/s3-encryption.sentinel`  
**Enforcement Level:** Hard fail  
**Purpose:** Ensures all S3 buckets have server-side encryption enabled

**Business Value:** Prevents data exposure and compliance violations

**Triggered by:**
- `checkout` workspace: order_data bucket
- `data-platform` workspace: customer_behavior_data bucket

---

### Required Tagging Policy

**File:** `policies/required-tags.sentinel`  
**Enforcement Level:** Hard fail  
**Purpose:** Enforces presence of required tags for all resources

**Required Tags:**
- `Environment` - Deployment environment (production, staging, dev)
- `Team` - Owning team name
- `CostCenter` - Business unit for chargeback
- `Owner` - Technical owner contact
- `ManagedBy` - Management method (terraform, manual, etc.)

**Business Value:** Enables cost attribution, resource tracking, and operational accountability

**Triggered by:**
- `data-platform` workspace: S3 bucket and RDS instance missing all tags

---

### Cost Threshold Policy

**File:** `policies/cost-threshold.sentinel`  
**Enforcement Level:** Soft fail (requires approval)  
**Purpose:** Flags resources with estimated monthly cost >$200

**Business Value:** Prevents surprise bills and enables cost governance

**Triggered by:**
- `data-platform` workspace: r5.2xlarge EC2 + db.r5.xlarge RDS = ~$900/month combined

---

## Business Impact

### Risk Mitigation
- **Zero production incidents** from unencrypted storage
- **Automated compliance** - policies prevent audit failures
- **Cost governance** - expensive resources require approval before provisioning

### Operational Efficiency
- **Deployment velocity:** 2-3 day manual reviews → <1 hour automated checks
- **Self-service infrastructure:** Developers get instant feedback, not manual gatekeeping
- **Scale without overhead:** Policies apply automatically to new teams and workspaces

### Visibility & Auditability
- **Centralized state management:** Complete view of deployed infrastructure
- **Audit trail:** Every change tracked (who, what, when, why)
- **State versioning:** Rollback capability and drift detection

---

## Technical Implementation

### Workspace Configuration

Each workspace is configured with:
- **VCS Integration:** GitHub repository monitoring `main` branch
- **Working Directory:** Team-specific path (e.g., `storefront/prod`)
- **Auto-apply:** Disabled - requires manual approval for visibility into approval workflow
- **AWS Credentials:** Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)

### State Management

- State files managed centrally in Terraform Cloud
- No local state files - prevents loss and enables collaboration
- State locking prevents concurrent modifications
- Version history enables rollback and audit compliance

### Policy Enforcement

- Policies written in Sentinel (HashiCorp's policy-as-code language)
- Policies run automatically during plan phase
- Hard fails block deployment; soft fails require approval
- Policy results visible in TFC UI and GitHub PR comments

---

## Setup Instructions

### Prerequisites

- Terraform Cloud account
- AWS account with IAM credentials
- GitHub account

### Environment Setup

**1. Clone repository**
```bash
git clone https://github.com/YOUR_USERNAME/acme-corp-tfc-demo.git
cd acme-corp-tfc-demo
```

**2. Create TFC workspaces**

In Terraform Cloud:
- Create organization: `acme-corp`
- Create three workspaces: `storefront`, `checkout`, `data-platform`

**3. Configure workspace VCS connections**

For each workspace:
- Connect to GitHub repository
- Branch: `main`
- Terraform Working Directory:
  - `storefront` → `storefront/prod`
  - `checkout` → `checkout/prod`
  - `data-platform` → `data-platform/prod`

**4. Set AWS credentials**

In each workspace Settings → Variables, add:
```
AWS_ACCESS_KEY_ID (environment variable, sensitive)
AWS_SECRET_ACCESS_KEY (environment variable, sensitive)
```

**5. Apply Sentinel policies**

In TFC Organization Settings → Policy Sets:
- Create policy set from VCS
- Repository: This repo
- Policy path: `policies/`
- Scope: Apply to all workspaces

**6. Trigger plans**

Plans run automatically on push to `main` branch, or manually via TFC UI.

---

## Architecture
```
Developer Workflow:
┌─────────────┐       ┌──────────────┐       ┌─────────────┐       ┌─────────┐
│   Developer │──────>│    GitHub    │──────>│     TFC     │──────>│   AWS   │
│  (git push) │       │  (repo/PR)   │       │ (plan/apply)│       │         │
└─────────────┘       └──────────────┘       └─────────────┘       └─────────┘
                                                     │
                                                     ▼
                                            ┌─────────────────┐
                                            │ Sentinel Policies│
                                            │  - Encryption   │
                                            │  - Tagging      │
                                            │  - Cost         │
                                            └─────────────────┘
```

**Key Components:**
- **GitHub:** Source of truth for Terraform code
- **Terraform Cloud:** Execution environment, state storage, policy enforcement
- **Sentinel Policies:** Automated governance checks
- **AWS:** Target infrastructure platform

---

## Key Differentiators

This demo demonstrates:

1. **Realistic business scenarios** - E-commerce use cases with actual team dynamics
2. **Policy-as-code governance** - Beyond basic workflow to show automated enforcement
3. **Multi-team orchestration** - Three workspaces showing different maturity levels
4. **Operational thinking** - Tagging, cost controls, audit trails for real-world operations
5. **Clear business value mapping** - Technical capabilities tied to stakeholder outcomes

---

## Resources

- [Terraform Cloud Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [Sentinel Policy Language](https://docs.hashicorp.com/sentinel)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [HashiCorp Learn - Terraform Cloud](https://learn.hashicorp.com/collections/terraform/cloud)

---

**Author:** Chase Erickson  
**Contact:** [Your Email]  
**Purpose:** HashiCorp Solutions Engineer Technical Exercise
