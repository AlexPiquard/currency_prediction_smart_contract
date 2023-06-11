# Smart-contract de jeu de prédiction de monté/descente d'actifs

Les cryptomonnaies sont connues pour leur grande volatilité. Le but de ce projet est de
proposer aux utilisateurs de parier sur la montée ou la descente d’actifs.

Utilisation de Chainlink Data Feeds comme source de vérité pour les prix.

Les fonctionnalités sont les suivantes :
- Tout utilisateur peut placer une prédiction sur une cryptomonnaie et sur la montée/descente.
- Les gains des gagnants sont payés par les mises des perdants.
- Le contrat conserve une commission d’un certain pourcentage sur les gains.

## Contract
https://sepolia.etherscan.io/address/0x4b898a5a4d8c7503c25d118cfeec34d63d69cd43

## Utilisation

- Ajouter une monnaie ou voir celles supportées (actuellement 'BTC' - BTC / USD).
- Parier sur la montée/descente avec `betIncrease` ou `betDecrease` en mentionnant 'BTC'.
- Attendre une variation du prix (https://data.chain.link/ethereum/mainnet/crypto-usd/btc-usd).
- Utiliser `result` pour générer les résultats et attribuer les gains.