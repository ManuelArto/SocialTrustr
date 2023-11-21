import matplotlib.pyplot as plt
import numpy as np

def entropy(p1, p2):
    p3 = 1 - p1 - p2
    terms = [p * (np.log2(p)) for p in [p1, p2, p3] if p > 0]
    return -np.sum(terms) / np.log2(3)

# Genera dati per il grafico
p1_values = np.linspace(0, 0.9, 10)
p2_values = np.linspace(0, 0.9, 10)
entropy_values = np.zeros((len(p1_values), len(p2_values)))

for i, p1 in enumerate(p1_values):
    for j, p2 in enumerate(p2_values):
        if p1 + p2 > 1.0:
            entropy_values[i, j] = np.nan
        else:
            entropy_values[i, j] = entropy(p1, p2)

# Crea il grafico 3D
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
p1_values, p2_values = np.meshgrid(p1_values, p2_values)

ax.plot_surface(p1_values, p2_values, entropy_values, cmap='viridis')

# Aggiungi etichette e titolo
ax.set_xlabel('p1')
ax.set_ylabel('p2')
ax.set_zlabel('Entropy')
ax.set_title('Entropy evaluation')

# Mostra il grafico
plt.show()