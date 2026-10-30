# Etapa 05 --- Disfarce e suspeita

## Pré-requisito

Etapa 04 validada.

## Objetivo

Adicionar a identidade central do jogo sem construir ainda todos os
sistemas de investigação.

## Tarefas

1.  Definir estados e parâmetros de suspeita em configuração
    centralizada.
2.  Implementar ao menos uma ação observável que aumente suspeita.
3.  Definir uma condição legível de estabilização ou redução da
    suspeita.
4.  Exibir o nível de suspeita na interface.
5.  Fazer a suspeita depender de acontecimentos verificáveis, não de
    aleatoriedade inexplicável.
6.  Garantir que o servidor seja responsável pelos valores críticos.
7.  Adicionar feedback contextual que ajude o jogador a entender o
    risco.

## Escopo mínimo

Não construir ainda patrulhas complexas, sistema de prisão, múltiplos
investigadores ou uma árvore de evidências completa.

## Critérios de aceite

-   [ ] Uma ação específica aumenta a suspeita.
-   [ ] O jogador consegue entender a causa.
-   [ ] O indicador reflete o estado real do servidor.
-   [ ] Os valores têm limites definidos.
-   [ ] Eventos repetidos não provocam aumentos duplicados inesperados.
-   [ ] O sistema não bloqueia o ciclo comercial normal.

## Ao concluir

Atualize `STATUS.md` e pare.
