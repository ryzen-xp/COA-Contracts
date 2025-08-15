# Gear Read Operations Documentation

## Overview

The Gear Read Operations system provides comprehensive read-only access to all gear-related information in the game. This system enables players to query item details, statistics, upgrade information, and perform advanced filtering and sorting operations.

## Features

### 1. Complete Item Details Access
- **Function**: `get_gear_details(item_id, session_id)`
- **Purpose**: Retrieve comprehensive information about any gear item
- **Returns**: `GearDetailsComplete` structure containing:
  - Basic gear properties (id, type, level, owner)
  - Calculated stats based on current upgrade level
  - Upgrade progression information
  - Ownership and availability status

### 2. Real-time Statistics Calculation
- **Function**: `get_calculated_stats(item_id, session_id)`
- **Purpose**: Get actual stats based on upgrade level and multipliers
- **Features**:
  - Dynamic stat calculation with upgrade multipliers
  - Type-specific stat enhancement (weapons, armor, vehicles, pets)
  - Performance-optimized calculations

### 3. Upgrade Planning Information
- **Function**: `get_upgrade_preview(item_id, target_level, session_id)`
- **Purpose**: Preview upgrade costs and resulting stats
- **Features**:
  - Material requirements calculation
  - Success rate information
  - Preview of stats at target level
  - Total cost calculation for multi-level upgrades

### 4. Advanced Inventory Management
- **Function**: `get_player_inventory(player, filters, pagination, sort, session_id)`
- **Purpose**: Manage and organize player inventory
- **Features**:
  - Filter by gear type, level range, ownership status
  - Sort by damage, defense, level, XP requirements
  - Pagination support for large inventories
  - Efficient batch operations

### 5. Equipped Gear Overview
- **Function**: `get_equipped_gear(player, session_id)`
- **Purpose**: View all equipped items and combined effects
- **Features**:
  - List all equipped items by slot
  - Calculate total damage and defense
  - Display set bonuses and combined effects
  - Identify empty equipment slots

### 6. Available Items Discovery
- **Function**: `get_available_items(player_xp, filters, pagination, session_id)`
- **Purpose**: Find items available for pickup
- **Features**:
  - Filter by XP requirements player can meet
  - Show spawned items available for collection
  - Location and spawn information
  - Rarity and type filtering

## Data Structures

### GearDetailsComplete
```cairo
struct GearDetailsComplete {
    gear: Gear,                           // Basic gear information
    calculated_stats: GearStatsCalculated, // Current stats with upgrades
    upgrade_info: Option<UpgradeInfo>,    // Upgrade possibilities
    ownership_status: OwnershipStatus,    // Ownership and availability
}
```

### GearStatsCalculated
```cairo
struct GearStatsCalculated {
    // Weapon stats
    damage: u64,
    range: u64,
    accuracy: u64,
    fire_rate: u64,
    
    // Armor stats
    defense: u64,
    durability: u64,
    weight: u64,
    
    // Vehicle stats
    speed: u64,
    armor: u64,
    fuel_capacity: u64,
    
    // Pet stats
    loyalty: u64,
    intelligence: u64,
    agility: u64,
}
```

### UpgradeInfo
```cairo
struct UpgradeInfo {
    current_level: u64,
    max_level: u64,
    can_upgrade: bool,
    next_level_cost: Option<UpgradeCost>,
    success_rate: Option<u8>,
    next_level_stats: Option<GearStatsCalculated>,
    total_upgrade_cost: Option<Array<(u256, u256)>>,
}
```

### Filtering Options
```cairo
struct GearFilters {
    gear_types: Option<Array<GearType>>,      // Filter by specific types
    min_level: Option<u64>,                   // Minimum upgrade level
    max_level: Option<u64>,                   // Maximum upgrade level
    ownership_filter: Option<OwnershipFilter>, // Ownership status
    min_xp_required: Option<u256>,            // Minimum XP requirement
    max_xp_required: Option<u256>,            // Maximum XP requirement
    spawned_only: Option<bool>,               // Only spawned items
}
```

## Usage Examples

### 1. Get Complete Item Information
```cairo
let item_details = gear_read_system.get_gear_details(item_id, session_id);
match item_details {
    Option::Some(details) => {
        // Access gear properties
        let level = details.gear.upgrade_level;
        let damage = details.calculated_stats.damage;
        let can_upgrade = details.upgrade_info.unwrap().can_upgrade;
    },
    Option::None => {
        // Item not found or invalid session
    }
}
```

### 2. Filter Player Inventory
```cairo
let filters = GearFilters {
    gear_types: Option::Some(array![GearType::Weapon, GearType::Armor]),
    min_level: Option::Some(5),
    max_level: Option::None,
    ownership_filter: Option::Some(OwnershipFilter::Owned),
    min_xp_required: Option::None,
    max_xp_required: Option::None,
    spawned_only: Option::None,
};

let pagination = PaginationParams { offset: 0, limit: 50 };
let sort = SortParams { sort_by: SortField::Damage, ascending: false };

let inventory = gear_read_system.get_player_inventory(
    player_address, 
    Option::Some(filters), 
    Option::Some(pagination), 
    Option::Some(sort), 
    session_id
);
```

### 3. Calculate Upgrade Costs
```cairo
let total_costs = gear_read_system.calculate_upgrade_costs(
    item_id, 
    target_level, 
    session_id
);

match total_costs {
    Option::Some(costs) => {
        // Check if player has required materials
        let (feasible, missing) = gear_read_system.check_upgrade_feasibility(
            item_id,
            target_level,
            player_materials,
            session_id
        );
    },
    Option::None => {
        // Cannot upgrade to target level
    }
}
```

### 4. Find Available Items
```cairo
let filters = GearFilters {
    gear_types: Option::Some(array![GearType::Weapon]),
    min_level: Option::None,
    max_level: Option::None,
    ownership_filter: Option::Some(OwnershipFilter::Available),
    min_xp_required: Option::None,
    max_xp_required: Option::Some(player_xp),
    spawned_only: Option::Some(true),
};

let available_items = gear_read_system.get_available_items(
    player_xp,
    Option::Some(filters),
    Option::Some(pagination),
    session_id
);
```

## Performance Considerations

### Session Validation
- All operations require valid session_id
- Read-only operations don't increment transaction count
- Auto-renewal for expiring sessions
- Efficient session parameter validation

### Query Optimization
- Batch operations where possible
- Pagination to prevent large result sets
- Efficient storage access patterns
- Cached calculations for frequently accessed data

### Gas Efficiency
- Pagination limits to prevent gas issues
- Optional detail levels (basic vs. complete)
- Optimized filtering algorithms
- Minimal storage reads per operation

## Security Features

### Access Control
- Session validation for all operations
- Owner verification for private information
- Read-only operations with no state changes
- Protection against unauthorized access

### Data Integrity
- Consistent data structure returns
- Proper error handling for invalid requests
- Validation of all input parameters
- Safe handling of missing or corrupted data

## Error Handling

### Common Error Cases
- Invalid session ID
- Expired or revoked sessions
- Item not found
- Insufficient permissions
- Invalid filter parameters
- Pagination out of bounds

### Error Response Pattern
```cairo
// Functions return Option<T> for nullable results
// Boolean returns for simple success/failure
// Tuple returns for complex results with error info
```

## Integration Guidelines

### Frontend Integration
1. Always validate session before making calls
2. Handle Option::None responses gracefully
3. Implement proper pagination for large datasets
4. Cache frequently accessed data when appropriate
5. Use batch operations for multiple items

### Backend Integration
1. Ensure proper session management
2. Implement efficient filtering algorithms
3. Monitor gas usage for large queries
4. Maintain data consistency across operations
5. Optimize storage access patterns

## Future Enhancements

### Planned Features
- Real-time market value integration
- Advanced sorting algorithms
- Item recommendation system
- Equipment optimization suggestions
- Cross-player item comparison
- Enhanced set bonus calculations
- Dynamic stat balancing
- Performance analytics and monitoring

### Extensibility
The system is designed to be easily extensible with:
- New gear types and categories
- Additional filtering criteria
- Enhanced sorting options
- Custom stat calculations
- Advanced query capabilities
- Integration with other game systems