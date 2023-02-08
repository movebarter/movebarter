# Movebarter
## 项目背景
Movebarter是一个基于SUI的物品交换平台，用户可以在该平台上进行相同/不同种类物品的交易，如：
* 同种nft交易(水浒英雄卡，宋江换武松)

## 模块拆分
项目主要分为两个模块，NFT & 订单。
* NFT模块提供了记录物品的基本信息并在不同账户间转移的功能。主要分为: 创建NFT、发行NFT、展示NFT
* 订单记录了被交易物品的id信息。主要分为: 创建订单、购买、取消订单

## 技术栈
* 前端: React
* 合约: SUI Move

## 参考
1. [基于eth的物物交换平台论文](https://www.readcube.com/articles/10.5195/ledger.2020.148)
2. [基于eth的物物交换平台](https://www.bartermachine.org/bloxberg/)
3. [Centrifuge协议](https://www.jinse.com/news/blockchain/1088309.html)

## 编译发布
sui move build
sui client publish . --gas-budget 300000

## 测试
sui move test