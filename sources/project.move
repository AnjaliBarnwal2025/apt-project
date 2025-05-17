
module OrganRegistry::DonorRegistry {
    use std::string::{String};
    use aptos_framework::account;
    use aptos_framework::signer;
    use aptos_std::table::{Self, Table};

    /// Error codes
    const E_ALREADY_REGISTERED: u64 = 1;
    const E_NOT_REGISTERED: u64 = 2;

    /// Struct representing a donor's information
    struct DonorInfo has store, drop {
        is_donor: bool,         // Whether the user is an organ donor
        blood_type: String,     // Blood type of the donor
        registered_at: u64,     // Timestamp when registered
    }

    /// Struct to store all donors in the system
    struct DonorRegistry has key {
        donors: Table<address, DonorInfo>,
    }

    /// Initialize the donor registry when the module is published
    public fun initialize(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        
        // Create and move the registry resource to the admin's account
        let donors = table::new<address, DonorInfo>();
        move_to(admin, DonorRegistry { donors });
    }

    /// Register as an organ donor
    public entry fun register_as_donor(
        account: &signer,
        blood_type: String,
        registry_owner: address
    ) acquires DonorRegistry {
        let user_addr = signer::address_of(account);
        let registry = borrow_global_mut<DonorRegistry>(registry_owner);
        
        // Check if user is already registered
        assert!(!table::contains(&registry.donors, user_addr), E_ALREADY_REGISTERED);
        
        // Create donor info and add to registry
        let donor_info = DonorInfo {
            is_donor: true,
            blood_type,
            registered_at: aptos_framework::timestamp::now_seconds(),
        };
        
        table::add(&mut registry.donors, user_addr, donor_info);
    }

    /// Update donor status (opt in or opt out)
    public entry fun update_donor_status(
        account: &signer,
        is_donor: bool,
        registry_owner: address
    ) acquires DonorRegistry {
        let user_addr = signer::address_of(account);
        let registry = borrow_global_mut<DonorRegistry>(registry_owner);
        
        // Check if user is registered
        assert!(table::contains(&registry.donors, user_addr), E_NOT_REGISTERED);
        
        // Update donor status
        let donor_info = table::borrow_mut(&mut registry.donors, user_addr);
        donor_info.is_donor = is_donor;
    }
}