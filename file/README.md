# Eco-Footprint Calculator

A comprehensive carbon footprint tracking and offset system built on the Stacks blockchain using Clarity smart contracts.

## Version 2.0 Features

### Enhanced Security & Bug Fixes
- Fixed `list-push` syntax error (replaced with `append`)
- Added comprehensive input validation and bounds checking
- Implemented proper error handling with meaningful error constants
- Added maximum entry limits to prevent blockchain bloat
- Enhanced data integrity with timestamp tracking

### Core Functionality

#### Eco-Footprint Contract (`eco-footprint.clar`)
- Track individual carbon footprint activities
- Store activity details with timestamps
- Calculate total carbon footprint per user
- User statistics and analytics
- Entry management (add/delete/reset)

#### Carbon Offset Contract (`carbon-offset.clar`)
- Purchase carbon offsets with different types
- Verification system for offset authenticity
- Dynamic pricing for different offset categories
- Cost calculation and tracking
- Administrative controls for pricing and verification

### Contract Features

#### Data Structures
```clarity
;; Footprint tracking
(define-map footprints
  ((user principal))
  ((total uint)
   (entries (list 100 (tuple (activity (string-ascii 32)) (amount uint) (timestamp uint))))))

;; Carbon offset tracking
(define-map carbon-offsets
  ((user principal))
  ((total-offset uint)
   (offsets (list 50 (tuple 
     (offset-type (string-ascii 32)) 
     (amount uint) 
     (timestamp uint) 
     (verified bool)
     (cost uint))))))
```

#### Security Features
- Input validation for all parameters
- Bounds checking for amounts and string lengths
- Authorization controls for administrative functions
- Protection against integer overflow/underflow
- Maximum entry limits to prevent resource exhaustion

## Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity and Stacks blockchain

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd eco-footprint-calculator
```

2. Install dependencies and setup:
```bash
clarinet check
```

3. Start local development environment:
```bash
./scripts/start-mocknet.sh
```

4. Deploy contracts:
```bash
./scripts/deploy.sh mocknet
```

### Usage Examples

#### Adding a Footprint Entry
```clarity
;; Add a car trip entry
(contract-call? .eco-footprint add-entry "car-trip" u50)

;; Add electricity usage
(contract-call? .eco-footprint add-entry "electricity" u120)
```

#### Purchasing Carbon Offsets
```clarity
;; Purchase tree planting offsets
(contract-call? .carbon-offset purchase-offset "tree-planting" u25)

;; Purchase renewable energy offsets
(contract-call? .carbon-offset purchase-offset "renewable-energy" u15)
```

#### Querying Data
```clarity
;; Get total footprint
(contract-call? .eco-footprint get-total 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Get verified offsets
(contract-call? .carbon-offset get-verified-offsets 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## API Reference

### Eco-Footprint Contract

#### Public Functions
- `add-entry(activity, amount)` - Add a carbon footprint entry
- `reset-footprint()` - Clear all user entries

#### Read-Only Functions
- `get-total(user)` - Get user's total carbon footprint
- `get-user-footprint(user)` - Get detailed user data
- `get-entry(user, entry-index)` - Get a specific entry by index
- `get-entry-count(user)` - Get number of entries for user
- `get-total-users()` - Get total registered users
- `get-average-footprint()` - Calculate average footprint

### Carbon Offset Contract

#### Public Functions
- `purchase-offset(offset-type, amount)` - Buy carbon offsets
- `verify-all-offsets(user)` - Verify all offsets for a user (admin only)
- `update-offset-price(offset-type, new-price)` - Update pricing (admin only)
- `change-verifier(new-verifier)` - Change admin (admin only)

#### Read-Only Functions
- `get-verified-offsets(user)` - Get total verified offsets
- `get-user-offsets(user)` - Get detailed offset data
- `get-offset-entry(user, offset-index)` - Get specific offset by index
- `get-offset-price(offset-type)` - Get current pricing
- `get-verifier()` - Get current admin address

## Offset Types

1. **Tree Planting** (`tree-planting`) - 10 units per offset
2. **Renewable Energy** (`renewable-energy`) - 15 units per offset  
3. **Carbon Capture** (`carbon-capture`) - 25 units per offset
4. **Forest Conservation** (`forest-conservation`) - 20 units per offset

## Error Codes

### Eco-Footprint Contract
- `u100` - Unauthorized access
- `u101` - Invalid amount (outside bounds)
- `u102` - Activity name too long
- `u103` - Maximum entries reached
- `u104` - User not found

### Carbon Offset Contract
- `u200` - Unauthorized access
- `u201` - Invalid amount
- `u202` - Invalid offset type
- `u203` - Insufficient balance
- `u204` - Offset not found

## Development Scripts

- `./scripts/deploy.sh [network]` - Deploy contracts to specified network
- `./scripts/start-mocknet.sh` - Start local mocknet environment
- `./scripts/reset-mocknet.sh` - Reset local mocknet database

## Testing

Run the test suite:
```bash
clarinet test
```

Run contract checks:
```bash
clarinet check
```

## Network Support

- **Mocknet** - Local development and testing
- **Testnet** - Stacks testnet deployment
- **Mainnet** - Production deployment (when ready)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Security Considerations

- All user inputs are validated
- Administrative functions are properly protected
- Resource usage is bounded to prevent DoS attacks
- No external dependencies that could introduce vulnerabilities
- Proper error handling prevents contract failures

## Future Roadmap

- [ ] Multi-signature verification system
- [ ] Integration with real carbon offset providers
- [ ] Mobile app interface
- [ ] Analytics dashboard
- [ ] Community challenges and rewards
- [ ] Integration with IoT devices for automatic tracking

## License

MIT License - see LICENSE file for details

## Support

For questions and support, please open an issue on GitHub or contact the development team.

---

**Version**: 2.0.0  
**Last Updated**: June 2025  
**Blockchain**: Stacks  
**Language**: Clarity
