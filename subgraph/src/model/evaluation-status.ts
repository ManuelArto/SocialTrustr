// * Cloned from ../schema.graphql

export class EvaluationStatus {
    static Evaluating: string = "Evaluating";
    static Evaluated: string = "Evaluated";
    static NotVerified_NotEnoughVotes: string = "NotVerified_NotEnoughVotes";
    static NotVerified_EvaluationEndedInATie: string = "NotVerified_EvaluationEndedInATie";
    
    static toEvaluationStatus(status: i32): string {
        switch (status) {
            case i32(0):
                return EvaluationStatus.Evaluating;
            case i32(1):
                return EvaluationStatus.Evaluated;
            case i32(2):
                return EvaluationStatus.NotVerified_NotEnoughVotes;
            case i32(3):
                return EvaluationStatus.NotVerified_EvaluationEndedInATie;
            default:
                return EvaluationStatus.Evaluated;
        }
    }
}