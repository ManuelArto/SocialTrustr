import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import { ContentCreated } from "../generated/ContentSharing/ContentSharing"

export function createContentCreatedEvent(
  id: BigInt,
  sender: Address,
  title: string,
  ipfsCid: string,
  chatName: string,
  parentContent: BigInt
): ContentCreated {
  let contentCreatedEvent = changetype<ContentCreated>(newMockEvent())

  contentCreatedEvent.parameters = new Array()

  contentCreatedEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromUnsignedBigInt(id))
  )
  contentCreatedEvent.parameters.push(
    new ethereum.EventParam("sender", ethereum.Value.fromAddress(sender))
  )
  contentCreatedEvent.parameters.push(
    new ethereum.EventParam("title", ethereum.Value.fromString(title))
  )
  contentCreatedEvent.parameters.push(
    new ethereum.EventParam("ipfsCid", ethereum.Value.fromString(ipfsCid))
  )
  contentCreatedEvent.parameters.push(
    new ethereum.EventParam("chatName", ethereum.Value.fromString(chatName))
  )
  contentCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "parentContent",
      ethereum.Value.fromUnsignedBigInt(parentContent)
    )
  )

  return contentCreatedEvent
}
