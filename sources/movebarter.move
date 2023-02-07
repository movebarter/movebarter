module movebarter::exchange {
  use std::option::{Self, Option};
  use sui::object::{Self, ID, UID};
  use sui::transfer::{transfer, share_object};
  use sui::tx_context::{Self, TxContext};
  use sui::object_table::{Self, ObjectTable};

  const ENftIdNotMatch: u64 = 1;
  const ENftPropertyNotMatch: u64 = 2;
  const ENotOrderOwner: u64 = 3;

  // we can get all nfts from one address
  // sui client objects
  // sui client object [object id]
  struct Nft has key, store {
      id: UID,
      name: vector<u8>,
      description: vector<u8>,
      property_value: vector<u8>,
  }

  struct Order has key, store {
    id: UID,
    base_token: Nft,
    target_token_id: Option<ID>,
    target_property_value: Option<vector<u8>>,
    owner: address,
  }

  struct Global has key {
    id: UID,
    orders: ObjectTable<ID, Order>,
  }

  fun init(
    ctx: &mut TxContext
    ){
      share_object(Global {
            id: object::new(ctx),
            orders: object_table::new(ctx),
      });
  }

  public entry fun mint(
    name: vector<u8>,
    description: vector<u8>, 
    property_value: vector<u8>,
    ctx: &mut TxContext,
    ) {
      let nft = Nft {
        id: object::new(ctx), 
        name, 
        description, 
        property_value, 
      };

      transfer(nft, tx_context::sender(ctx));
  }

  public entry fun submit_order(
    global: &mut Global,
    base_token: Nft,
    target_token_id: Option<ID>,
    target_property_value: Option<vector<u8>>,
    ctx: &mut TxContext) {

      let order = Order{
        id: object::new(ctx),
        base_token, 
        target_token_id, 
        target_property_value, 
        owner: tx_context::sender(ctx)
      };
      object_table::add(&mut global.orders, object::id(&order), order);
  }

  public entry fun take_order(
    global: &mut Global,
    nft: Nft,
    oid: ID,
    ctx: &mut TxContext
    ) {
      //let Order { id, base_token, target_token_id, target_property_value, owner} = order;
      let Order {id, base_token, target_token_id, target_property_value, owner } = object_table::remove(&mut global.orders, oid);

      if (option::is_some(&target_token_id)) {
        let inter_nft_id = object::uid_to_inner(&nft.id);
        assert!(option::borrow(&target_token_id) == &inter_nft_id, ENftIdNotMatch);
      };

      if (option::is_some(&target_property_value)) {
        let inter_nft_property_value = nft.property_value;
        assert!(option::borrow(&target_property_value) == &inter_nft_property_value, ENftPropertyNotMatch);
      }; 

      transfer(nft, owner);
      transfer(base_token, tx_context::sender(ctx));

      object::delete(id);
      option::destroy_none(target_token_id);
      option::destroy_none(target_property_value);
  }

  public entry fun cancel_order(
    global: &mut Global,
    oid: ID,
    ctx: &mut TxContext
    ) {
      //let Order { id, base_token, target_token_id, target_property_value, owner} = order;
      let Order {id, base_token, target_token_id, target_property_value, owner } = object_table::remove(&mut global.orders, oid);

      let user = tx_context::sender(ctx);
      assert!(&user == &owner, ENotOrderOwner);

      object::delete(id);
      option::destroy_none(target_token_id);
      option::destroy_none(target_property_value);

      transfer(base_token, owner);
  }
}