module movebarter::exchange {
  use std::option::{Option};
  use sui::object::{Self, ID, UID};
  use sui::transfer::{transfer, share_object};
  use sui::tx_context::{Self, TxContext};
  use sui::object_table::{Self, ObjectTable};
  use std::vector;

  const ENftIdNotMatch: u64 = 1;
  const ENftPropertyNotMatch: u64 = 2;
  const ENotOrderOwner: u64 = 3;
  const LengthNotMatch: u64 = 4;
  const NFTSIsNotEmpty: u64 = 5;

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
    target_token_ids: vector<ID>,
    target_property_value: Option<vector<u8>>,
    owner: address,
  }

  struct Global has key {
    id: UID,
    orders: ObjectTable<ID, Order>,
    oids: vector<ID>,
  }

  fun init(
    ctx: &mut TxContext
    ){
      share_object(Global {
            id: object::new(ctx),
            orders: object_table::new(ctx),
            oids: vector<ID>[],
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
    target_token_ids: vector<ID>,
    target_property_value: Option<vector<u8>>,
    ctx: &mut TxContext) {
      let order = Order{
        id: object::new(ctx),
        base_token, 
        target_token_ids, 
        target_property_value, 
        owner: tx_context::sender(ctx),
      };
      vector::insert(&mut global.oids, object::uid_to_inner(&order.id), 0);
      object_table::add(&mut global.orders, object::id(&order), order);
  }

  public entry fun take_order(
    global: &mut Global,
    nfts: vector<Nft>,
    oid: ID,
    ctx: &mut TxContext
    ) {
      let Order {id, base_token, target_token_ids, target_property_value: _, owner } = object_table::remove(&mut global.orders, oid);

      // if (option::is_some(&target_token_id)) {
      //   let inter_nft_id = object::uid_to_inner(&nft.id);
      //   assert!(option::borrow(&target_token_id) == &inter_nft_id, ENftIdNotMatch);
      // };

      // if (option::is_some(&target_property_value)) {
      //   let inter_nft_property_value = nft.property_value;
      //   assert!(option::borrow(&target_property_value) == &inter_nft_property_value, ENftPropertyNotMatch);
      // }; 

      let nfts_len = vector::length(&nfts);
      let target_token_ids_len = vector::length(&target_token_ids);
      let i = 0;

      assert!(nfts_len == target_token_ids_len, LengthNotMatch);

      while (i < nfts_len) {
            let nft = vector::borrow(&nfts, i);
            let inter_nft_id = object::uid_to_inner(&nft.id);

            let target_token_id = vector::borrow(&target_token_ids, i);
            assert!(target_token_id == &inter_nft_id, ENftIdNotMatch);

            i = i +1;
      };

      let (rt, i) = vector::index_of(&mut global.oids, &oid);
      if(rt) {
        vector::remove(&mut global.oids, i);
      };

      let i = 0;
      while (i < nfts_len) {
        let nft = vector::pop_back(&mut nfts);
        transfer(nft, owner);
        i = i + 1;
      };
      
      transfer(base_token, tx_context::sender(ctx));

      assert!(vector::is_empty(&nfts), NFTSIsNotEmpty);

      object::delete(id);
      vector::destroy_empty(nfts);
  }

  public entry fun cancel_order(
    global: &mut Global,
    oid: ID,
    ctx: &mut TxContext
    ) {
      let Order {id, base_token, target_token_ids: _, target_property_value: _, owner } = object_table::remove(&mut global.orders, oid);

      let user = tx_context::sender(ctx);
      assert!(&user == &owner, ENotOrderOwner);

      let (rt, i) = vector::index_of(&mut global.oids, &oid);
      if(rt) {
        vector::remove(&mut global.oids, i);
      };

      object::delete(id);

      transfer(base_token, owner);
  }

  #[test_only]
  public fun get_nft_id(nft: &Nft): ID {
      object::uid_to_inner(&nft.id)
  }

  #[test_only]
  public fun get_last_order_id(global: &mut Global): ID {
      let oid = vector::pop_back(&mut global.oids);
      vector::insert(&mut global.oids, oid, 0);
      oid
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
      init(ctx);
  }
}

#[test_only]
module movebarter::exchangeTest {
  use sui::test_scenario::Self;
  use movebarter::exchange::{Self, Nft, Global};
  use std::option::{Self};
  //use sui::object::{Self};
  use std::vector;

  #[test]
  fun test_take_order_exchange() {
    let owner = @0xACE;
    let bidder1 = @0x11;
    let bidder2 = @0x22;

    let scenario_val = test_scenario::begin(owner);
    let scenario = &mut scenario_val;

    //test_init
    exchange::init_for_testing(test_scenario::ctx(scenario));

    //test_mint
    //let order_id = option::none();
    test_scenario::next_tx(scenario, bidder1);
    let name = b"bear";
    let description = b"monkey for Jay";
    let property_value = b"Hot";
    exchange::mint(name, description, property_value, test_scenario::ctx(scenario));
    test_scenario::next_tx(scenario, owner);
    test_scenario::next_tx(scenario, bidder1);
    let nft = test_scenario::take_from_sender<Nft>(scenario);
    let raw_nft_id_1 = exchange::get_nft_id(&nft);
    test_scenario::return_to_sender(scenario, nft);


    let nfts = vector::empty();
    test_scenario::next_tx(scenario, bidder2);
    let name2 = b"monkey";
    let description2 = b"monkey for Sun";
    let property_value2 = b"Fast";
    exchange::mint(name2, description2, property_value2, test_scenario::ctx(scenario));

    test_scenario::next_tx(scenario, owner);
    test_scenario::next_tx(scenario, bidder2);
    let nft2 = test_scenario::take_from_sender<Nft>(scenario);
    let raw_nft_id_2 = exchange::get_nft_id(&nft2);
    let nft_id_2 = exchange::get_nft_id(&nft2);
    vector::push_back(&mut nfts, nft2);


    test_scenario::next_tx(scenario, bidder2);
    let name3 = b"kitty";
    let description3 = b"kitty for crypt";
    let property_value3 = b"Small";
    exchange::mint(name3, description3, property_value3, test_scenario::ctx(scenario));

    test_scenario::next_tx(scenario, owner);
    test_scenario::next_tx(scenario, bidder2);
    let nft3 = test_scenario::take_from_sender<Nft>(scenario);
    let raw_nft_id_3 = exchange::get_nft_id(&nft3);
    let nft_id_3 = exchange::get_nft_id(&nft3);
    vector::push_back(&mut nfts, nft3);

    //test_submit_order
    test_scenario::next_tx(scenario, bidder1);
    {
      let global_val = test_scenario::take_shared<Global>(scenario);
      let global = &mut global_val;

      let nft = test_scenario::take_from_sender<Nft>(scenario);

      let nft_ids = vector::empty();
      vector::push_back(&mut nft_ids, nft_id_2);
      vector::push_back(&mut nft_ids, nft_id_3);
      exchange::submit_order(global, nft, nft_ids, option::none(), test_scenario::ctx(scenario));
      test_scenario::return_shared(global_val);
    };

    // test_take_order
    test_scenario::next_tx(scenario, bidder2);
    {
      let global_val = test_scenario::take_shared<Global>(scenario);
      let global = &mut global_val;

      let oid = exchange::get_last_order_id(global);
      
      exchange::take_order(global, nfts, oid, test_scenario::ctx(scenario));
      test_scenario::return_shared(global_val);
    };

    test_scenario::next_tx(scenario, bidder1);
    {
      let nft = test_scenario::take_from_address_by_id<Nft>(scenario, bidder1, raw_nft_id_2);
      test_scenario::return_to_sender(scenario, nft);
    };

    test_scenario::next_tx(scenario, bidder1);
    {
      let nft = test_scenario::take_from_address_by_id<Nft>(scenario, bidder1, raw_nft_id_3);
      test_scenario::return_to_sender(scenario, nft);
    };

    test_scenario::next_tx(scenario, bidder2);
    {
      let nft = test_scenario::take_from_address_by_id<Nft>(scenario, bidder2, raw_nft_id_1);
      test_scenario::return_to_sender(scenario, nft);
    };
    test_scenario::end(scenario_val);
  }

  #[test]
  fun test_cancel_order_exchange() {
    let owner = @0xACE;
    let bidder1 = @0x11;
    let bidder2 = @0x22;

    let scenario_val = test_scenario::begin(owner);
    let scenario = &mut scenario_val;

    //test_init
    exchange::init_for_testing(test_scenario::ctx(scenario));

    //test_mint
    //let order_id = option::none();
    test_scenario::next_tx(scenario, bidder1);
    let name = b"bear";
    let description = b"monkey for Jay";
    let property_value = b"Hot";
    exchange::mint(name, description, property_value, test_scenario::ctx(scenario));


    test_scenario::next_tx(scenario, bidder2);
    let name2 = b"monkey";
    let description2 = b"monkey for Sun";
    let property_value2 = b"Fast";
    exchange::mint(name2, description2, property_value2, test_scenario::ctx(scenario));

    test_scenario::next_tx(scenario, owner);
    test_scenario::next_tx(scenario, bidder2);
    let nft = test_scenario::take_from_sender<Nft>(scenario);
    let nft_id_2 = exchange::get_nft_id(&nft);
    test_scenario::return_to_sender(scenario, nft);


    //test_submit_order
    test_scenario::next_tx(scenario, bidder1);
    {
      let global_val = test_scenario::take_shared<Global>(scenario);
      let global = &mut global_val;

      let nft = test_scenario::take_from_sender<Nft>(scenario);

      let nft_ids = vector::empty();
      vector::push_back(&mut nft_ids, nft_id_2);
      exchange::submit_order(global, nft, nft_ids, option::none(), test_scenario::ctx(scenario));
      test_scenario::return_shared(global_val);
    };

    // test_cancel_order
    test_scenario::next_tx(scenario, bidder1);
    {
      let global_val = test_scenario::take_shared<Global>(scenario);
      let global = &mut global_val;

      let oid = exchange::get_last_order_id(global);      
      exchange::cancel_order(global, oid, test_scenario::ctx(scenario));

      test_scenario::return_shared(global_val);
    };

    test_scenario::end(scenario_val);
  }
}