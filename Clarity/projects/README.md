ONE


Guardian Gateway proposal (Clarity contract)

Bitcoin-anchored oracle network for Stacks DeFi

Guardian Gateway is the first oracle protocol that anchors every price feed to Bitcoin's blockchain, providing secure, reliable data for DeFi applications on Stacks. By combining Stacks' Proof-of-Transfer with an 8-layer validation system, Guardian Gateway offers something no other oracle can: Bitcoin-grade security with financial insurance against bad data.
Why Guardian Gateway?
The Problem: DeFi protocols rely on price oracles that can be manipulated or fail catastrophically. Oracle failures have caused over $240M in losses (Mango Markets: $110M, Cream Finance: $130M).
The Solution: Every price feed is validated through 8 security layers and anchored to Bitcoin's blockchain before DeFi protocols can use it. Oracle operators stake STX and Bitcoin as bonds—bad data gets slashed, good data gets rewarded.
Key Features

Bitcoin-Anchored Security - Every data point inherits Bitcoin's finality through Stacks' Proof-of-Transfer
8-Layer Validation System - Multi-source verification, consensus mechanisms, and slashing conditions
Insurance Fund - Protocols receive compensation if bad data causes losses
Permissionless - Anyone can become an oracle operator by staking bonds
Self-Sustaining - Revenue from protocol subscriptions and query fees
100% Open Source - MIT licensed for maximum transparency and community trust

Technology Stack

Smart Contracts: Clarity (Stacks blockchain)
Frontend: React + TypeScript
Oracle Network: Distributed validators with automated price feeds
Data Sources: Multi-source aggregation from major exchanges and oracles

Current Status

✅ Smart contracts testnet-validated
✅ dApp with functional wallet integration
🔄 Security audit in progress
🔄 Protocol integrations underway

For Developers
Guardian Gateway provides secure price feeds for:

DEX protocols (automated market makers)
Lending/borrowing platforms
Synthetic asset protocols
Any DeFi application requiring reliable price data



TWO


# DEFI PROTOCOL HEALTH MONITOR - Stacks Implementation

## Project Overview

A Bitcoin-secured security scorecard and early warning system for DeFi protocols on Stacks. This dApp merges DeFi functionality with security monitoring, providing users with real-time protocol health scores and automated risk alerts.

### Why This Project

After completing Guardian Gateway, I took extra time to think about my next Code4STX dApp rather than rushing into development. While I knew a DeFi project made sense given the ecosystem's focus, I didn't want to build another cookie-cutter DEX or lending protocol. I would like to combine DeFi functionality with security monitoring. I believe this project can leverage my experience with systems  while building something genuinely useful...a tool that helps users make safer decisions in the DeFi space.

## Core Value Proposition

**Problem**: Users have no easy way to assess the safety of DeFi protocols on Stacks before investing.

**Solution**: Real-time health scores (A-F grading) based on security, liquidity, decentralization, and operational metrics, all anchored to Bitcoin via Proof of Transfer.

**Differentiator**: Independent, user-facing tool (not controlled by exchanges/protocols) with Bitcoin-level security guarantees.

## Key Features

### Free Tier
- Basic protocol health scores (A-F)
- 7-day historical data
- Public dashboard access
- Top 20 protocols view

### Premium Tier
- Full score breakdowns across 4 categories
- 30-90 day historical trends
- Customizable alert thresholds
- Email/Push/Webhook notifications
- Protocol comparison tools
- PDF report exports
- API access (Pro tier)

### Protocol Partnership
- Verified badge for high-scoring protocols
- Featured dashboard placement
- Direct user alert integration
- Marketing kit and widgets

## Technical Architecture

### Smart Contract (Clarity)
```clarity
;; Main contract: health-monitor.clar
;; Core data structures:
- protocol-scores (map)
- historical-scores (map)
- user-alerts (map)
- security/liquidity/decentralization/operational metrics (maps)

;; Key functions:
- record-protocol-score
- get-protocol-health
- set-user-alert
- check-alert-threshold
```

### Frontend (React + TypeScript)
- Public dashboard for score viewing
- User authentication via Stacks wallets
- Alert configuration interface
- Historical data visualization (Recharts)
- Protocol comparison views

### Backend Services
- Protocol scanner (monitors Stacks blockchain)
- Smart contract analyzer
- Risk calculation engine
- Alert manager
- Time-series database for historical data

### Bitcoin Integration
- All scores anchored to Bitcoin via Proof of Transfer
- Immutable score history on Bitcoin blockchain
- Tamper-proof audit trail

## Scoring Methodology

### Security Score (40% weight)
- Audit status (0-30 pts)
- Admin key configuration (0-20 pts)
- Time locks (0-15 pts)
- Bug bounty program (0-15 pts)
- Code upgradeability (0-20 pts)

### Liquidity Score (25% weight)
- TVL size (0-25 pts)
- Liquidity depth (0-25 pts)
- Daily volume (0-20 pts)
- TVL volatility (0-15 pts)
- Exit liquidity capacity (0-15 pts)

### Decentralization Score (20% weight)
- Whale concentration (0-30 pts)
- Governance distribution (0-20 pts)
- Oracle dependency (0-25 pts)
- User base size (0-15 pts)
- Team transparency (0-10 pts)

### Operational Score (15% weight)
- Uptime record (0-20 pts)
- Historical incidents (0-20 pts)
- Track record/age (0-15 pts)
- Documentation quality (0-10 pts)

**Final Grade**:
- A (90-100): Excellent - Very Safe
- B (80-89): Good - Generally Safe
- C (70-79): Fair - Use with Caution
- D (60-69): Poor - Significant Risks
- F (<60): Critical - Avoid/High Risk


## Success Metrics

### Technical
- Track 20+ protocols by month 3
- 99.9% uptime for monitoring
- <5 second score update latency
- Zero smart contract vulnerabilities

### User Impact
- Prevent users from investing in 1 risky protocol
- Alert users before 1 major incident occurs
- Become the go-to safety resource for Stacks DeFi

Positioning: "Independent security infrastructure for the Stacks DeFi ecosystem"

## Competitive Advantages

1. **Bitcoin Security**: Only PoR tool anchored to Bitcoin
2. **Independence**: Not controlled by protocols/exchanges
3. **User-First**: Built for users, not institutions
4. **Clarity Smart Contracts**: Predictable, secure
5. **Open Source**: Community-verifiable scoring
6. **First Mover**: No equivalent on Stacks

