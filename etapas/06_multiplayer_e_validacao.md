# Etapa 06 --- Multiplayer e validação do servidor

## Pré-requisito

Etapas 02 a 05 validadas.

## Objetivo

Verificar se o núcleo suporta vários jogadores sem duplicação de itens,
dinheiro ou ações importantes.

## Tarefas

1.  Auditar os RemoteEvents e RemoteFunctions existentes.
2.  Validar parâmetros, distância, permissões, estado e frequência das
    solicitações.
3.  Testar dois jogadores tentando interagir com o mesmo objeto.
4.  Testar vendas simultâneas e estoque limitado.
5.  Tratar saída ou desconexão durante uma ação.
6.  Garantir que dados econômicos sejam alterados exclusivamente por
    lógica confiável no servidor.
7.  Testar com múltiplos clientes no Studio, se a ferramenta estiver
    disponível.

## Critérios de aceite

-   [ ] Solicitações inválidas são recusadas.
-   [ ] O mesmo objeto não é duplicado por corrida entre jogadores.
-   [ ] Uma venda não é processada duas vezes.
-   [ ] A saída de um jogador não deixa objetos ou estados
    permanentemente presos.
-   [ ] A interface dos clientes converge para o estado confirmado pelo
    servidor.
-   [ ] O teste multiplayer foi executado ou sua ausência foi
    documentada claramente.

## Ao concluir

Atualize `STATUS.md` e pare.
