import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import { NewsCreated } from "../generated/NewsSharing/NewsSharing"

export function createNewsCreatedEvent(
  id: BigInt,
  sender: Address,
  title: string,
  ipfsCid: string,
  chatName: string,
  parentNews: BigInt
): NewsCreated {
  let newsCreatedEvent = changetype<NewsCreated>(newMockEvent())

  newsCreatedEvent.parameters = new Array()

  newsCreatedEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromUnsignedBigInt(id))
  )
  newsCreatedEvent.parameters.push(
    new ethereum.EventParam("sender", ethereum.Value.fromAddress(sender))
  )
  newsCreatedEvent.parameters.push(
    new ethereum.EventParam("title", ethereum.Value.fromString(title))
  )
  newsCreatedEvent.parameters.push(
    new ethereum.EventParam("ipfsCid", ethereum.Value.fromString(ipfsCid))
  )
  newsCreatedEvent.parameters.push(
    new ethereum.EventParam("chatName", ethereum.Value.fromString(chatName))
  )
  newsCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "parentNews",
      ethereum.Value.fromUnsignedBigInt(parentNews)
    )
  )

  return newsCreatedEvent
}
