module myAccount::movebarter {
  use aptos_token::token;
  use std::string::{Self, String};
  use aptos_token::token::{TokenId, TokenDataId};
  use aptos_token::property_map::{Self, PropertyMap, PropertyValue};
  use aptos_framework::account::{SignerCapability, create_resource_account};
  use aptos_framework::account;
  use std::vector;
  use aptos_framework::timestamp;
  use std::signer::address_of;
  #[test_only]
  use aptos_framework::account::create_account_for_test;
  use aptos_framework::coin;
  #[test_only]
  use aptos_framework::aptos_coin;
  use aptos_framework::aptos_coin::AptosCoin;
  use aptos_std::simple_map::{Self, SimpleMap};
  use std::option::{Self, Option};

  struct Order has store {
    base_token_id: TokenId,
    target_token_id: Option<TokenId>,
    target_propert_map: PropertyMap,
  }

  struct Orders has key{
    orders: SimpleMap<u64, Order>,
    //events: OrderEvents,
    next_order_id: u64,
  }

  public entry fun init(
    _sender:&signer, 
    _maximum:u64, 
    _expiration_timestamp:u64){
  }

  public entry fun mint(
    _sender:&signer, 
    name: String,
    description: String, 
    property_keys: vector<String>,
    property_values: vector<vector<u8>>,
    property_types: vector<String>) {
  }

  public entry fun submit_order(_sender:&signer) {
  }

  public entry fun take_order(
    _sender:&signer, 
    token_id:TokenId) {
  }

  public entry fun cancel_order(
    _sender:&signer, 
    _order_id: u64) {
  }
}