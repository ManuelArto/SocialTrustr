import { BigInt, store } from "@graphprotocol/graph-ts";

import { NewsEvaluated as NewsEvaluatedEvent, NewsValidationStarted as NewsValidationStartedEvent } from "../generated/NewsEvaluation/NewsEvaluation"
import { NewsEntry, Evaluation } from "../generated/schema"


export function handleNewsValidationStarted(event: NewsValidationStartedEvent): void {
}

export function handleNewsEvaluated(event: NewsEvaluatedEvent): void {
}