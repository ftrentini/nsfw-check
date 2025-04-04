import pandas as pd
import matplotlib.pyplot as plt
import os

# Caminho do CSV
csv_path = "./scan_results/scan_report.csv"
output_img = "./scan_results/nsfw_pizza.png"

if not os.path.exists(csv_path):
    print("CSV file not found. Run the scan script first.")
    exit(1)

# Carrega dados
df = pd.read_csv(csv_path)

# Categoriza
def categorize(row):
    if row['label'] == 'SAFE':
        return 'SAFE'
    elif row['nsfw_score'] >= 0.99:
        return 'NSFW 99–100%'
    elif row['nsfw_score'] >= 0.95:
        return 'NSFW 95–99%'
    else:
        return 'NSFW 90–95%'

df['category'] = df.apply(categorize, axis=1)

# Contagem
counts = df['category'].value_counts()

# Cores
colors = {
    'SAFE': '#4CAF50',
    'NSFW 90–95%': '#FFA500',
    'NSFW 95–99%': '#FF5722',
    'NSFW 99–100%': '#F44336'
}

# Gera gráfico
plt.figure(figsize=(6, 6))
plt.pie(counts, labels=counts.index, autopct='%1.1f%%', startangle=140,
        colors=[colors[c] for c in counts.index])
plt.title("NSFW Scan Results 🍕")
plt.tight_layout()
plt.savefig(output_img)
plt.show()
