import { NewsEvaluated as NewsEvaluatedEvent } from "../generated/NewsEvaluation/NewsEvaluation"
import { Evaluation } from "../generated/schema"
import { EvaluationStatus } from "./model/evaluation-status"


export function handleNewsEvaluated(event: NewsEvaluatedEvent): void {
    let evaluation = Evaluation.load(event.params.id.toString())
    if (evaluation == null) {
        return;
    }

    evaluation.evaluation = event.params.evaluation
    evaluation.confidence = event.params.confidence
    evaluation.status = EvaluationStatus.toEvaluationStatus(event.params.status)
    evaluation.evaluationsCount = event.params.evaluationsCount
    evaluation.save()
}