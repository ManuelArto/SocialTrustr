import numpy as np
import matplotlib.pyplot as plt

def monte_carlo_simulation(num_trusted, num_iterations, stake_valutazione, stake_condivisione):
    trust_scores_history = []
    token_trs_history = []
    entropy_history = []
    iterations = 0

    trustlevels = np.full(num_trusted, 50.0)
    trs_tokens = np.full(num_trusted, 500.0)

    for _ in range(num_iterations):
        # Utente casuale condivide il contenuto e mette in stake
        sharer = np.random.choice(NUM_TRUSTED)
        if trs_tokens[sharer] >= STAKE_CONDIVISIONE:
            trs_tokens[sharer] -= STAKE_CONDIVISIONE
        else:
            continue  # Skip iteration if not enough tokens to share

        # Simulazione di valutazioni basate sulla fiducia e affidabilità degli utenti
        evaluators = np.setdiff1d(np.arange(NUM_TRUSTED), sharer)
        sharer_reliability = trustlevels[sharer] / 100.0

        # Generazione di probabilità di valutazione basata sulla fiducia dell'utente condividente
        eval_probabilities = np.random.normal(loc=sharer_reliability, scale=0.2, size=len(evaluators))
        eval_probabilities = np.clip(eval_probabilities, 0.4, 0.9)

        # Simulazione di correttezza della valutazione
        correct_evaluation = np.random.rand(len(evaluators)) < eval_probabilities

        # Check if evaluators have enough tokens for the evaluation
        confidence_scores = eval_probabilities[trs_tokens[evaluators] >= STAKE_VALUTAZIONE]
        correct_evaluation = correct_evaluation[trs_tokens[evaluators] >= STAKE_VALUTAZIONE]
        evaluators =  evaluators[trs_tokens[evaluators] >= STAKE_VALUTAZIONE]

        if len(evaluators) == 0:
            continue  # Skip iteration if no evaluator has enough tokens for evaluation

        trs_tokens[evaluators] -= STAKE_VALUTAZIONE

        # Calcolo Trust Scores
        scores_of_true = np.sum(
            trustlevels[evaluators[correct_evaluation]]
            * confidence_scores[correct_evaluation]
        )
        score_of_false = np.sum(
            trustlevels[evaluators[~correct_evaluation]]
            * confidence_scores[~correct_evaluation]
        )

        # Determina la validità del contenuto
        CONTENT_EVALUATION = scores_of_true > score_of_false

        # Calcolo entropia dei Trust Scores
        probs = [
            np.sum(confidence_scores[correct_evaluation] / len(evaluators)),
            np.sum(confidence_scores[~correct_evaluation] / len(evaluators)),
            0
        ]
        probs[2] = 1 - probs[0] - probs[1] if probs[0] + probs[1] < 1 else 0

        entropy = 0
        for i in range(3):
            if probs[i] > 0:
                probs[i] = probs[i] / np.sum(probs)
                entropy += -(probs[i] * np.log2(probs[i]))
        entropy /= np.log2(3)

        if not CONTENT_EVALUATION:
            correct_evaluation = np.logical_not(correct_evaluation)
            punishment = np.sum(STAKE_CONDIVISIONE)
        else:
            trs_tokens[sharer] += STAKE_CONDIVISIONE
            punishment = 0


        # Ritorno di token a chi ha valutato correttamente
        trs_tokens[evaluators[correct_evaluation]] += STAKE_VALUTAZIONE
        # Ritorno dei token a chi ha valutato non correttamente in base al confidence score
        trs_tokens[evaluators[~correct_evaluation]] += STAKE_VALUTAZIONE * (
            1 - confidence_scores[~correct_evaluation]
        )

        # Calcolo Punishment
        punishment += np.sum(STAKE_VALUTAZIONE * confidence_scores[~correct_evaluation])

        # Aggiungiamo lo sharer a confidence_scores e correct_evaluation
        evaluators = np.insert(evaluators, sharer-1, sharer)
        confidence_scores = np.insert(confidence_scores, sharer-1, 1.0)
        correct_evaluation = np.insert(correct_evaluation, sharer-1, CONTENT_EVALUATION)

        # Redistribuzione dei token
        trs_tokens[evaluators[correct_evaluation]] += (
            confidence_scores[correct_evaluation]
            / np.sum(confidence_scores[correct_evaluation])
        ) * punishment

        # Aggiornamento dell'affidabilità degli utenti
        trustlevels[evaluators[~correct_evaluation]] -= (
            trustlevels[evaluators[~correct_evaluation]]
            * confidence_scores[~correct_evaluation]
            * (1.0 - entropy)
        )
        trustlevels[evaluators[correct_evaluation]] += (
            (100 - trustlevels[evaluators[correct_evaluation]])
            * confidence_scores[correct_evaluation]
            * (1.0 - entropy)
        ) / M

        # Save data for plotting
        trust_scores_history.append(np.copy(trustlevels))
        token_trs_history.append(np.copy(trs_tokens))
        entropy_history.append(entropy)
        iterations += 1

    return trust_scores_history, token_trs_history, entropy_history, iterations

def plot_trust_scores(trust_scores, num_trusted, iterations):
    plt.figure(figsize=(10, 6))
    for i in range(num_trusted):
        plt.plot(range(iterations), [scores[i] for scores in trust_scores], label=f'Utente {i + 1}')

    plt.title('Trust Scores over Iterations')
    plt.xlabel('Iteration')
    plt.ylabel('Trust Score')
    plt.legend()
    plt.show()

def plot_token_trs(token_trs, num_trusted, iterations):
    plt.figure(figsize=(10, 6))
    for i in range(num_trusted):
        plt.plot(range(iterations), [tokens[i] for tokens in token_trs], label=f'Utente {i + 1}')

    plt.title('Token TRS over Iterations')
    plt.xlabel('Iteration')
    plt.ylabel('Token TRS')
    plt.legend()
    plt.show()

def plot_entropy(entropy, iterations):
    plt.figure(figsize=(10, 6))
    plt.plot(range(iterations), entropy_history, label='Entropy')
    plt.title('Entropy over Iterations')
    plt.xlabel('Iteration')
    plt.ylabel('Entropy')
    plt.legend()
    plt.show()

# Constants
NUM_TRUSTED = 5
NUM_ITERATIONS = 100
STAKE_VALUTAZIONE = 10
STAKE_CONDIVISIONE = 20
M = 2  # Costante per la ricompensa

trust_scores_history, token_trs_history, entropy_history, iterations = monte_carlo_simulation(
    NUM_TRUSTED, NUM_ITERATIONS, STAKE_VALUTAZIONE, STAKE_CONDIVISIONE
)

plot_trust_scores(trust_scores_history, NUM_TRUSTED, iterations)
plot_token_trs(token_trs_history, NUM_TRUSTED, iterations)
plot_entropy(entropy_history, iterations)
