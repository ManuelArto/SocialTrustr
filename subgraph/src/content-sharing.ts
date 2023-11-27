import { BigInt } from "@graphprotocol/graph-ts";

import { ContentCreated as ContentCreatedEvent } from "../generated/ContentSharing/ContentSharing"
import { Content, Evaluation } from "../generated/schema"
import { EvaluationStatus } from "./model/evaluation-status"


export function handleContentCreated(event: ContentCreatedEvent): void {
  let content = new Content(event.params.id.toString())
  content.sender = event.params.sender
  content.title = event.params.title
  content.ipfsCid = event.params.ipfsCid
  content.chatName = event.params.chatName
  content.forwarded = []
  // Parent Content Infos
  content.isForwaded = event.params.parentContent.notEqual(BigInt.zero())
  if (content.isForwaded) {
    updateParentForwardedContent(content, event.params.parentContent)
    content.parentContent = event.params.parentContent.toString()
    // Link to parent content evaluation
    content.evaluation = Content.load(content.parentContent!)!.evaluation
  } else {
    content.parentContent = "0"
    content.evaluation = createInitialEvaluation(event).id
  }

  content.blockNumber = event.block.number
  content.blockTimestamp = event.block.timestamp
  content.transactionHash = event.transaction.hash

  content.save()
}

function updateParentForwardedContent(content: Content, parentId: BigInt): void {
  let parentContent: Content = Content.load(parentId.toString())!

  let forwarded = parentContent.forwarded
  forwarded!.push(content.id)
  parentContent.forwarded = forwarded

  parentContent.save()
}


function createInitialEvaluation(event: ContentCreatedEvent): Evaluation {
  let evaluation = new Evaluation(event.params.id.toString())
  evaluation.status = EvaluationStatus.Evaluating

  evaluation.save()
  return evaluation
}