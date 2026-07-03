# Feira Fácil

Aplicativo Flutter para controle simples, organizado e prático de compras de mercado, feira, farmácia, açougue e compras emergenciais.

O objetivo do **Feira Fácil** é ajudar o usuário a cadastrar produtos, organizar categorias, registrar compras, adicionar itens com quantidade e preço, acompanhar gastos e analisar relatórios de consumo.

---

## Visão Geral

Com o Feira Fácil, o usuário pode:

- Criar uma conta com e-mail e senha.
- Fazer login online.
- Usar o app offline após o primeiro login online.
- Cadastrar categorias.
- Cadastrar produtos.
- Criar compras mensais, semanais, emergenciais ou por tipo.
- Adicionar itens dentro de uma compra.
- Editar e excluir registros conforme as regras do app.
- Finalizar ou reabrir compras.
- Consultar relatórios de gastos.
- Acompanhar pendências de sincronização.
- Personalizar tema claro/escuro.
- Alterar a cor principal do app.
- Sincronizar dados com a nuvem.

---

## Tecnologias Utilizadas

- Flutter
- Dart
- Riverpod
- GoRouter
- Firebase Auth
- Cloud Firestore
- Hive
- Shared Preferences
- Intl
- UUID
- FL Chart

---

## Arquitetura do Projeto

O projeto segue uma organização baseada em separação de responsabilidades, utilizando Riverpod para gerenciamento de estado.

Estrutura principal:

```txt
lib/
├── core/
│   ├── constants/
│   └── theme/
├── database/
├── models/
├── repositories/
├── routes/
├── services/
├── utils/
├── viewmodels/
├── views/
└── widgets/