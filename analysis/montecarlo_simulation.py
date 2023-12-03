import numpy as np
import matplotlib.pyplot as plt

def custom_round(x, prec=2, base=.1):
    return round(base * round(float(x)/base),prec)

def monte_carlo_simulation(num_trusted, num_iterations, stake_valutazione, stake_condivisione, reset=False):
    trustlevels = np.full(num_trusted, 50.0)
    trs_tokens = np.full(num_trusted, 500.0)

    trust_levels_history = [np.copy(trustlevels)]
    token_trs_history = [np.copy(trs_tokens)]
    entropy_gain_losses_history = {}
    for i in range(0, 101, 10):
        entropy_gain_losses_history[i/100] = []
    iterations = 0

    for _ in range(num_iterations):
        # Utente casuale condivide il contenuto e mette in stake
        sharer = np.random.choice(NUM_TRUSTED)
        if trs_tokens[sharer] >= STAKE_CONDIVISIONE:
            trs_tokens[sharer] -= STAKE_CONDIVISIONE
        else:
            continue  # Skip iteration if not enough tokens to share

        evaluators = np.setdiff1d(np.arange(NUM_TRUSTED), sharer)

        # Simulazione di valutazioni pseudo realistiche
        # sharer_reliability = trustlevels[sharer] / 100.0
        confidence_scores = np.random.uniform(0.4, 1.1, len(evaluators))
        correct_evaluation = np.random.choice([True, False], len(evaluators), p=[0.7, 0.3])

        # Check if evaluators have enough tokens for the evaluation
        confidence_scores = confidence_scores[trs_tokens[evaluators] >= STAKE_VALUTAZIONE]
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


        # Calcolo Ricompense e Penalizzazioni

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
        trust_levels_history.append(np.copy(trustlevels))
        token_trs_history.append(np.copy(trs_tokens))

        # calculate gain/loss delta of previous trustlevels for each entropy range
        diff = abs(trust_levels_history[-1] - trust_levels_history[-2])
        entropy_gain_losses_history[custom_round(entropy)].append(np.sum(diff))

        if reset:
            trustlevels = np.full(num_trusted, 50.0)
            trs_tokens = np.full(num_trusted, 500.0)
            trust_levels_history = [np.copy(trustlevels)]
            token_trs_history = [np.copy(trs_tokens)]

        iterations += 1

    return trust_levels_history, token_trs_history, entropy_gain_losses_history, iterations

def plot_data(data, num_trusted,iterations, string_data, bar_hover=True, offset=0):
    data_avg = np.mean(np.array(data[1:]).reshape(-1, 10, num_trusted), axis=1)

    bottom = np.zeros(len(data_avg))
    for i in range(num_trusted):
        plt.bar(range(10, (len(data_avg)+1)*10, 10), data_avg[:, i], label=f'Utente {i + 1}', bottom=bottom, width=9)

        for j in range(len(data_avg)):
            plt.text((j+1) * 10, (data_avg[j, i]/2)+bottom[j], round(data_avg[j, i]), ha = 'center', va = 'center', fontdict={'size': 18})

        if bar_hover:
            bottom += data_avg[:, i]
        else:
            bottom += np.array([offset])

    plt.title(f'Media {string_data} ogni 10 iterazioni per ogni Utente')
    plt.xlabel('Iterazioni')
    plt.ylabel(f'Somma {string_data}')
    plt.legend()
    plt.show()

def plot_entropy_delta_boxplot(entropy_gain_losses_history):
    box_data = entropy_gain_losses_history.values()
    plt.boxplot(box_data, positions=list(entropy_gain_losses_history.keys()), widths=0.05, manage_ticks=False)

    plt.title('Box Plot of Delta incremento/riduzione per ogni Entropy Range')
    plt.xlabel('Entropy Range')
    plt.ylabel('Delta incremento/riduzione Trust Levels')
    plt.xticks(list(entropy_gain_losses_history.keys()))

    plt.show()

# Constants
NUM_TRUSTED = 10
NUM_ITERATIONS = 200
STAKE_VALUTAZIONE = 10
STAKE_CONDIVISIONE = 20
M = 2.5  # Costante per la ricompensa
plt.rcParams.update({'font.size': 24})


# Entropy => ripetizioni
_, _, entropy_gain_losses_history, _ = monte_carlo_simulation(
    NUM_TRUSTED, 10000, STAKE_VALUTAZIONE, STAKE_CONDIVISIONE, True
)
plot_entropy_delta_boxplot(entropy_gain_losses_history)

# TrustLevel e Token TRS => iterazioni
trust_levels_history, token_trs_history, _, iterations = monte_carlo_simulation(
    NUM_TRUSTED, NUM_ITERATIONS, STAKE_VALUTAZIONE, STAKE_CONDIVISIONE
)
plot_data(trust_levels_history, NUM_TRUSTED, iterations,  "Affidabilità")
plot_data(token_trs_history, NUM_TRUSTED, iterations, "Token TRS")
