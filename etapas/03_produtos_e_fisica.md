# Etapa 03 --- Produtos, transporte e física

## Pré-requisito

Etapa 02 validada.

## Objetivo

Permitir que o jogador manipule mercadorias e altere o estoque por meio
de ações reais.

## Tarefas

1.  Definir um produto e uma caixa usando dados centralizados.
2.  Implementar pegar, carregar, soltar e colocar o objeto em uma
    posição válida.
3.  Escolher uma estratégia física adequada para o Roblox e documentar a
    decisão.
4.  Implementar uma prateleira com capacidade e quantidade de estoque.
5.  Validar no servidor a distância, a disponibilidade do objeto e a
    ação solicitada.
6.  Tratar objetos inválidos, jogadores desconectados e tentativas
    simultâneas.
7.  Adicionar feedback visual e, se houver asset válido, áudio de
    interação.

## Requisitos técnicos

-   Não confie no cliente para definir livremente o estado final do
    objeto.
-   Evite teleportes inesperados, objetos presos e duplicação de
    mercadorias.
-   Não crie uma conexão por frame para cada objeto sem justificativa.
-   Mantenha os parâmetros físicos configuráveis.

## Critérios de aceite

-   [ ] O jogador pega e solta um objeto.
-   [ ] O objeto pode ser colocado na prateleira.
-   [ ] A quantidade de estoque muda corretamente.
-   [ ] Não é possível duplicar o objeto por interações repetidas.
-   [ ] Objetos em estado inválido têm recuperação ou erro tratado.
-   [ ] O fluxo foi testado ou as limitações foram documentadas.

## Ao concluir

Atualize `STATUS.md` e pare.
