import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { ContentCreated } from "../generated/schema"
import { ContentCreated as ContentCreatedEvent } from "../generated/ContentSharing/ContentSharing"
import { handleContentCreated } from "../src/content-sharing"
import { createContentCreatedEvent } from "./content-sharing-utils"

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
    let parentContent = BigInt.fromI32(234)
    let newContentCreatedEvent = createContentCreatedEvent(
      id,
      sender,
      title,
      ipfsCid,
      chatName,
      parentContent
    )
    handleContentCreated(newContentCreatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("ContentCreated created and stored", () => {
    assert.entityCount("ContentCreated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "ContentCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "sender",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "ContentCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "title",
      "Example string value"
    )
    assert.fieldEquals(
      "ContentCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "ipfsCid",
      "Example string value"
    )
    assert.fieldEquals(
      "ContentCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "chatName",
      "Example string value"
    )
    assert.fieldEquals(
      "ContentCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "parentContent",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
