# Tokenized Autonomous Vehicle Maintenance Systems

A comprehensive blockchain-based vehicle maintenance management system built on Stacks using Clarity smart contracts.

## System Overview

This system consists of four interconnected smart contracts that manage different aspects of vehicle maintenance:

### 1. Diagnostic Monitoring Contract (`diagnostic-monitor.clar`)
- Tracks vehicle performance metrics
- Identifies maintenance needs based on sensor data
- Records diagnostic events and alerts
- Manages vehicle health scores

### 2. Service Scheduling Contract (`service-scheduler.clar`)
- Coordinates maintenance appointments
- Manages oil changes, tire rotations, and routine maintenance
- Tracks service history and intervals
- Handles service provider assignments

### 3. Warranty Tracking Contract (`warranty-tracker.clar`)
- Manages manufacturer guarantees
- Tracks warranty coverage periods
- Records warranty claims and resolutions
- Validates warranty eligibility

### 4. Parts Sourcing Contract (`parts-sourcer.clar`)
- Locates genuine replacement components
- Manages parts inventory and pricing
- Tracks supplier information
- Handles parts ordering and delivery

## Features

- **Tokenized System**: Each vehicle is represented as an NFT
- **Decentralized**: No single point of failure
- **Transparent**: All maintenance records on-chain
- **Automated**: Smart contract-driven processes
- **Secure**: Cryptographic verification of all transactions

## Contract Architecture

Each contract is designed to be independent while sharing common data structures for vehicle identification and maintenance records.

## Getting Started

1. Deploy contracts to Stacks testnet
2. Register vehicles using the diagnostic monitor
3. Schedule maintenance through the service scheduler
4. Track warranties and source parts as needed

## Testing

Run the test suite using:
\`\`\`bash
npm test
\`\`\`

## License

MIT License
