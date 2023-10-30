import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { NewsCreated } from "../generated/schema"
import { NewsCreated as NewsCreatedEvent } from "../generated/NewsSharing/NewsSharing"
import { handleNewsCreated } from "../src/news-sharing"
import { createNewsCreatedEvent } from "./news-sharing-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let id = BigInt.fromI32(234)
    let sender = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let title = "Example string value"
    let ipfsCid = "Example string value"
    let chatName = "Example string value"
    let parentNews = BigInt.fromI32(234)
    let newNewsCreatedEvent = createNewsCreatedEvent(
      id,
      sender,
      title,
      ipfsCid,
      chatName,
      parentNews
    )
    handleNewsCreated(newNewsCreatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("NewsCreated created and stored", () => {
    assert.entityCount("NewsCreated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "NewsCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "sender",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "NewsCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "title",
      "Example string value"
    )
    assert.fieldEquals(
      "NewsCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "ipfsCid",
      "Example string value"
    )
    assert.fieldEquals(
      "NewsCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "chatName",
      "Example string value"
    )
    assert.fieldEquals(
      "NewsCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "parentNews",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
