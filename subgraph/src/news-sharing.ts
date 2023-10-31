import { BigInt, store } from "@graphprotocol/graph-ts";

import { NewsCreated as NewsCreatedEvent } from "../generated/NewsSharing/NewsSharing"
import { NewsData, Evaluation } from "../generated/schema"


export function handleNewsCreated(event: NewsCreatedEvent): void {
  let news = new NewsData(event.params.id.toString())
  news.sender = event.params.sender
  news.title = event.params.title
  news.ipfsCid = event.params.ipfsCid
  news.chatName = event.params.chatName
  news.forwarded = []
  news.evaluation = createInitialEvaluation(event).id
  // Parent News Infos
  news.isForwaded = event.params.parentNews.notEqual(BigInt.zero())
  if (news.isForwaded) {
    updateParentForwardedNews(news, event.params.parentNews)
    news.parentNews = event.params.parentNews.toString()
  } else {
    news.parentNews = "0"
  }

  news.blockNumber = event.block.number
  news.blockTimestamp = event.block.timestamp
  news.transactionHash = event.transaction.hash

  news.save()
}

function updateParentForwardedNews(news: NewsData, parentId: BigInt): void {
  let parentNews: NewsData = (store.get("NewsData", parentId.toString()) as NewsData)
  
  let forwarded = parentNews.forwarded
  forwarded!.push(news.id)
  parentNews.forwarded = forwarded

  parentNews.save()
}


function createInitialEvaluation(event: NewsCreatedEvent): Evaluation {
  let evaluation = new Evaluation(event.params.id.toString());
  evaluation.status = "NotStarted"
  
  evaluation.save()
  return evaluation;
}