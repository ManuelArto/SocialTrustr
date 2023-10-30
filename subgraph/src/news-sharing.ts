import { NewsCreated as NewsCreatedEvent } from "../generated/NewsSharing/NewsSharing"
import { NewsCreated } from "../generated/schema"

export function handleNewsCreated(event: NewsCreatedEvent): void {
  let entity = new NewsCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.NewsSharing_id = event.params.id
  entity.sender = event.params.sender
  entity.title = event.params.title
  entity.ipfsCid = event.params.ipfsCid
  entity.chatName = event.params.chatName
  entity.parentNews = event.params.parentNews

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
