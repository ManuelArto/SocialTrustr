import numpy as np
import matplotlib.pyplot as plt

# Lists to store data for plotting
trust_scores_history = []
token_trs_history = []
affidabilita_history = []

# Costanti del sistema
STAKE_VALUTAZIONE = 10
STAKE_CONDIVISIONE = 20

# Parametri iniziali
NUM_TRUSTED = 10
NUM_ITERATIONS = 1000
M = 2  # Costante per la ricompensa

# Inizializzazione degli utenti
trustlevels = np.full(NUM_TRUSTED, 50.0)
trs_tokens = np.full(NUM_TRUSTED, 500.0)

# Simulazione del test MonteCarlo
iterations = 0
for _ in range(NUM_ITERATIONS):
    # Utente casuale condivide il contenuto e mette in stake
    sharer = np.random.choice(NUM_TRUSTED)
    if trs_tokens[sharer] >= STAKE_CONDIVISIONE:
        trs_tokens[sharer] -= STAKE_CONDIVISIONE
    else:
        continue  # Skip iteration if not enough tokens to share

    # Simulazione di valutazioni pseudo-randomiche escludendo l'utente condividente
    evaluators = np.setdiff1d(np.arange(NUM_TRUSTED), sharer)
    confidence_scores = np.random.uniform(0.1, 1.0, len(evaluators))
    correct_evaluation = np.random.choice([True, False], len(evaluators), p=[0.5, 0.5])

    # Check if evaluators have enough tokens for the evaluation
    confidence_scores = confidence_scores[trs_tokens[evaluators] >= STAKE_VALUTAZIONE]
    correct_evaluation = correct_evaluation[trs_tokens[evaluators] >= STAKE_VALUTAZIONE]
    evaluators = evaluators[trs_tokens[evaluators] >= STAKE_VALUTAZIONE]
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
    iterations += 1

# Visualizzazione dei risultati
# for i in range(NUM_TRUSTED):
    # print(f"Utente {i + 1}: Token TRS = {trs_tokens[i]}, Affidabilità = {trustlevels[i]}")

# Plot Trust Scores over iterations
plt.figure(figsize=(10, 6))
for i in range(NUM_TRUSTED):
    plt.plot(range(iterations), [scores[i] for scores in trust_scores_history], label=f'Utente {i + 1}')

plt.title('Trust Scores over Iterations')
plt.xlabel('Iteration')
plt.ylabel('Trust Score')
plt.legend()
plt.show()

# Plot Token TRS over iterations
plt.figure(figsize=(10, 6))
for i in range(NUM_TRUSTED):
    plt.plot(range(iterations), [tokens[i] for tokens in token_trs_history], label=f'Utente {i + 1}')

plt.title('Token TRS over Iterations')
plt.xlabel('Iteration')
plt.ylabel('Token TRS')
plt.legend()
plt.show()