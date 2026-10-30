# Etapa 04 --- Clientes e vendas

## Pré-requisito

Etapa 03 validada.

## Objetivo

Fechar o primeiro ciclo comercial: cliente entra, procura um produto,
compra e sai.

## Tarefas

1.  Criar um NPC cliente usando um modelo disponível ou um protótipo
    explicitamente provisório.
2.  Implementar estados claros: Entrando, Procurando, Comprando, Saindo
    e Recuperação de caminho.
3.  Usar PathfindingService quando adequado e tratar caminhos
    bloqueados.
4.  Implementar preço, estoque e saldo no servidor.
5.  Garantir que cada compra seja processada uma única vez.
6.  Atualizar a interface a partir do estado confirmado pelo servidor.
7.  Configurar limites de NPCs e frequência de atualização.

## Critérios de aceite

-   [ ] O NPC chega à loja ou falha de maneira controlada.
-   [ ] O NPC só compra se houver produto disponível.
-   [ ] Uma compra válida altera estoque e dinheiro exatamente uma vez.
-   [ ] Compra inválida não gera dinheiro.
-   [ ] NPC sem caminho não fica preso para sempre.
-   [ ] O ciclo pode ser repetido.
-   [ ] O desempenho básico foi considerado.

## Ao concluir

Atualize `STATUS.md` e pare.
