import { BigInt } from "@graphprotocol/graph-ts";

import { NewsCreated as NewsCreatedEvent } from "../generated/NewsSharing/NewsSharing"
import { NewsEntry, Evaluation } from "../generated/schema"


export function handleNewsCreated(event: NewsCreatedEvent): void {
  let news = new NewsEntry(event.params.id.toString())
  news.sender = event.params.sender
  news.title = event.params.title
  news.ipfsCid = event.params.ipfsCid
  news.chatName = event.params.chatName
  news.forwarded = []
  // Parent News Infos
  news.isForwaded = event.params.parentNews.notEqual(BigInt.zero())
  if (news.isForwaded) {
    updateParentForwardedNews(news, event.params.parentNews)
    news.parentNews = event.params.parentNews.toString()
    // Link to parent news evaluation
    news.evaluation = NewsEntry.load(news.parentNews)!.evaluation;
  } else {
    news.parentNews = "0"
    news.evaluation = createInitialEvaluation(event).id
  }

  news.blockNumber = event.block.number
  news.blockTimestamp = event.block.timestamp
  news.transactionHash = event.transaction.hash

  news.save()
}

function updateParentForwardedNews(news: NewsEntry, parentId: BigInt): void {
  let parentNews: NewsEntry = NewsEntry.load(parentId.toString())!

  let forwarded = parentNews.forwarded
  forwarded!.push(news.id)
  parentNews.forwarded = forwarded

  parentNews.save()
}


function createInitialEvaluation(event: NewsCreatedEvent): Evaluation {
  let evaluation = new Evaluation(event.params.id.toString());
  evaluation.status = "Evaluating"

  evaluation.save()
  return evaluation;
}