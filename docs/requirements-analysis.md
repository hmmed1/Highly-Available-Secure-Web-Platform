# Client Requirements Discovery & Engineering Thinking

## Purpose

The projects in this series are designed to train more than technical implementation.

A real infrastructure engineer does not start by choosing AWS services. They first need to understand the problem the client is trying to solve.

Throughout this series, projects are treated as simulated client engagements. The objective is to practice the complete engineering process:

1. Understand the client's business problem.
2. Ask useful technical and business questions.
3. Identify requirements and constraints.
4. Separate requirements from implementation decisions.
5. Identify unknowns and assumptions.
6. Design an architecture that satisfies the requirements.
7. Explain and defend technical decisions.
8. Implement the solution.
9. Test whether the solution actually satisfies the requirements.
10. Document the result, trade-offs, limitations, and lessons learned.

The goal is to develop the ability to think and communicate like an engineer, not simply learn how to configure cloud services.

---

# 1. The Client Conversation

For each project, the client initially provides a business problem rather than an AWS architecture.

For example:

> "We are a small company preparing to launch a new web application."

The client may explain that security, availability, growth, access control, backups, or cost are important.

However, the client may not know which cloud services should be used.

That is the engineer's responsibility.

The engineer should therefore ask questions before designing the solution.

---

# 2. Questions Asked During Level 1

## Application Usage

### Question

How many users do you expect initially?

### Client Answer

Around **500 registered users** during the first few months.

### Why this matters

This gives an initial indication of the expected scale of the platform.

However, registered users are not the same as simultaneous users, so another question is necessary.

---

## Peak Concurrency

### Question

How many users do you expect to be active at the same time during normal peak periods?

### Client Answer

Approximately **50–80 active users simultaneously** during normal peak periods.

### Why this matters

Concurrency is more useful for infrastructure capacity planning than simply knowing the number of registered users.

It helps us reason about the expected workload and later determine appropriate compute capacity through testing and measurements.

---

## Growth

### Question

Do you expect the number of users or traffic to grow significantly?

### Client Answer

The user base is expected to grow significantly over the next **1–2 years**.

There may also be occasional marketing campaigns that cause traffic to increase several times above normal levels.

### Why this matters

The architecture should not be designed only for today's workload.

The infrastructure needs a way to increase capacity as demand increases without requiring the entire platform to be manually rebuilt.

---

## Large Traffic Increase

### Question

What should happen if traffic increases dramatically, for example by 10×?

### Client Answer

A 10× increase is not expected regularly, but during a major marketing campaign the application should remain usable rather than crash.

Ideally, the infrastructure should handle increased demand without requiring manual rebuilding.

### Why this matters

This introduces a **scalability requirement**.

It also forces us to think about the difference between:

* normal capacity
* temporary traffic spikes
* long-term growth

These may require different scaling strategies.

---

## Geographic Requirements

### Question

Do you have a required AWS region or data residency requirement?

### Client Answer

There is no strict AWS region requirement.

However, the company prefers application and customer data to be reasonably close to European customers.

### Why this matters

This gives us flexibility when selecting the deployment region while providing a reason to consider European AWS regions.

The client has expressed a preference rather than an absolute technical constraint.

---

## Infrastructure Access

### Question

Who needs access to the infrastructure?

### Client Answer

The development team needs access for deployment and troubleshooting.

One system administrator needs broader infrastructure management access.

### Why this matters

Not every employee should receive the same level of cloud permissions.

This introduces the need for **role-based access control and least privilege**.

---

## Developer Permissions

### Question

Should developers have unrestricted access to the AWS environment?

### Client Answer

No.

Developers should have access to the resources required for application development, deployment, and troubleshooting, but they should not have unrestricted administrator access.

The system administrator requires broader permissions.

### Why this matters

This leads to a separation of responsibilities.

A likely direction is:

* Developer permissions → limited to required resources/actions
* Administrator permissions → broader infrastructure management
* IAM → identity and permission management

The exact IAM policies should be determined during the implementation rather than assumed during the initial requirements discussion.

---

## Internet Exposure

### Question

Should all infrastructure components be directly accessible from the Internet?

### Client Answer

No.

Only the components required to serve the web application should be exposed.

### Why this matters

This creates an important security boundary.

The application does not need every infrastructure component to be Internet-facing.

A major architectural principle follows:

> **Minimize the attack surface by exposing only what needs to be publicly reachable.**

---

## Availability

### Question

What should happen if a normal application server fails?

### Client Answer

A failure of a normal server should ideally not cause a user-visible outage.

### Why this matters

This is an **availability and fault-tolerance requirement**.

The architecture therefore needs redundancy so that the failure of one component does not automatically result in application downtime.

This is different from simply saying:

> "Use two Availability Zones."

The Availability Zone strategy is an **engineering decision** made to satisfy the availability requirement.

---

## Larger Infrastructure Failure

### Question

What should happen if there is a larger infrastructure failure?

### Client Answer

A larger infrastructure failure may result in a short interruption, preferably measured in minutes rather than hours.

### Why this matters

This establishes a different level of availability.

The client expects normal component failures to be handled transparently, while a larger failure may have a limited recovery window.

This distinction helps determine how much complexity and cost the architecture should introduce.

---

# 3. Backup & Recovery

## Question

How important is customer data, and what should happen if data is accidentally deleted or becomes corrupted?

### Client Answer

Customer data is important.

The company requires regular backups and the ability to restore data after accidental deletion or database corruption.

### Why this matters

This creates a **backup and recovery requirement**.

It is important to distinguish this from high availability.

High availability helps keep the service running when infrastructure fails.

Backups help recover data when something goes seriously wrong, such as:

* accidental deletion
* corruption
* incorrect changes
* other recovery scenarios

A standby database is therefore not a replacement for backups.

---

# 4. Reproducibility

## Question

Should the infrastructure be configured manually or recreated automatically?

### Client Answer

The infrastructure should be reproducible and deployable automatically rather than requiring engineers to manually recreate the environment.

### Why this matters

This creates an **Infrastructure as Code** requirement.

The infrastructure should be represented as code so that the environment can be consistently recreated.

For this project, Terraform is used to implement that requirement.

---

# 5. Cost

## Question

Does the company have an unlimited infrastructure budget?

### Client Answer

No.

The company is small and wants the solution to remain reasonably cost-conscious while still meeting the availability and security requirements.

### Why this matters

Cost is an engineering constraint.

The goal is not:

> "Build the most expensive architecture possible."

The goal is:

> **Meet the requirements with an appropriate level of complexity and cost.**

Every additional highly available or managed component should therefore have a reason.

---

# 6. Unknowns We Identified

Not every requirement can be perfectly defined during the first client conversation.

Important unknowns include:

* Exact application technology and resource requirements
* Exact traffic patterns
* Maximum expected traffic during campaigns
* Exact monthly infrastructure budget
* Required backup retention period
* Exact Recovery Point Objective (RPO)
* Exact Recovery Time Objective (RTO)
* Long-term growth rate
* Detailed application performance requirements

These unknowns should not simply be invented.

Instead, they should be documented as assumptions, constraints, or questions that can be refined later.

---

# 7. Requirements vs Architecture Decisions

One of the most important lessons from this project is the difference between a **requirement** and an **implementation decision**.

### Requirement

> The application should remain available if an individual application server fails.

### Engineering decision

> Run application capacity across multiple Availability Zones and use load balancing and health checks.

---

### Requirement

> Only the necessary components should be accessible from the Internet.

### Engineering decision

> Keep application and database resources private and expose only the required entry point.

---

### Requirement

> Infrastructure should scale when demand increases.

### Engineering decision

> Use an Auto Scaling mechanism with appropriate scaling policies and monitoring.

---

### Requirement

> Customer data must be recoverable.

### Engineering decision

> Use an appropriate managed database backup and recovery strategy.

---

This distinction is critical.

**The client tells us what the system needs to achieve.
The engineer determines how to achieve it.**

---

# 8. The Engineering Thought Process

The process we want to practice throughout this project series is:

```text
Business Problem
       ↓
Client Questions
       ↓
Requirements
       ↓
Constraints & Unknowns
       ↓
Engineering Analysis
       ↓
Architecture
       ↓
Technology Selection
       ↓
Implementation
       ↓
Testing
       ↓
Evidence
       ↓
Documentation
       ↓
Review & Improvement
```

This process prevents a common beginner mistake:

```text
"I know AWS services"
        ↓
"Let's use EC2"
        ↓
"Let's use RDS"
        ↓
"Let's use ALB"
```

Instead, we want:

```text
"What problem are we solving?"
        ↓
"What does the client actually require?"
        ↓
"What could go wrong?"
        ↓
"What constraints exist?"
        ↓
"What architecture satisfies those requirements?"
        ↓
"Which technologies best implement that architecture?"
```

---

# 9. Why This Matters

Cloud engineering is not simply knowing what an AWS service does.

A professional engineer needs to be able to explain:

* Why a component exists
* Why it is configured a certain way
* What requirement it satisfies
* What happens when it fails
* What security risk it addresses
* What alternatives were considered
* What trade-offs exist
* What the limitations are
* How the architecture can evolve

The projects in this series therefore intentionally require requirements analysis and architecture decisions before implementation.

---

# 10. What This Series Is Training

Each project should progressively develop three areas of capability.

### Technical Skills

Examples:

* AWS
* Networking
* Linux
* Terraform
* Python
* Docker
* CI/CD
* Monitoring
* Security
* Automation

### Engineering Skills

Examples:

* Requirements analysis
* Architecture design
* Troubleshooting
* Testing
* Failure analysis
* Capacity planning
* Cost awareness
* Trade-off analysis
* Documentation

### Professional Communication

Examples:

* Asking clients the right questions
* Explaining technical concepts clearly
* Translating business requirements into technical requirements
* Defending architecture decisions
* Communicating limitations honestly
* Documenting decisions so another engineer can understand them

The goal is to develop all three together.

---

# 11. Simulated Client Engagement

The projects in this repository are training exercises presented as simulated client engagements.

They are not presented as real commercial projects or professional client experience.

The purpose is to practice the same reasoning process used in real engineering work:

> **Understand → Question → Analyze → Design → Build → Test → Document → Defend.**

As the projects become more advanced, the client requirements will become less explicit and more ambiguous.

The objective is to gradually become comfortable taking an incomplete business problem and turning it into a defensible technical solution.
