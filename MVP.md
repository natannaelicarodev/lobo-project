# MVP --- Wolf in Sheep's Clothing

## 1. Objetivo

Validar um núcleo de jogo pequeno, funcional e divertido antes de
investir em conteúdo avançado, modelagem final ou sistemas extensos.

**Promessa do MVP:** administrar uma pequena loja como um lobo
disfarçado de ovelha, transportar mercadorias, atender clientes e evitar
comportamentos suspeitos.

## 2. O que está dentro do MVP

### Ambiente

-   Uma única loja compacta.
-   Área pública com entrada, prateleiras e balcão.
-   Pequena área de estoque.
-   Uma área reservada que pode ser usada para demonstrar a mecânica de
    suspeita.
-   Navegação clara, sem obstáculos que bloqueiem o fluxo principal.

### Jogador

-   Personagem controlável com movimentação padrão do Roblox ou sistema
    existente.
-   Representação provisória do lobo disfarçado de ovelha, caso não haja
    modelo final disponível.
-   Uma interação contextual para pegar, carregar, soltar ou colocar
    objetos.
-   Feedback claro para ações válidas e inválidas.

### Mercadorias

-   Pelo menos um tipo de produto.
-   Caixas ou unidades de produto que possam ser transportadas.
-   Estoque com quantidade real.
-   Prateleira com capacidade definida.
-   Reposição validada pelo servidor.

### Clientes

-   Um NPC cliente funcional.
-   Caminho de entrada, procura, compra e saída.
-   Tratamento básico para falta de estoque ou caminho bloqueado.
-   Um limite configurável de clientes simultâneos.

### Economia

-   Saldo inicial configurável.
-   Preço de compra/valor de venda definido no servidor.
-   Venda apenas quando houver estoque e a transação for válida.
-   Atualização do saldo e da quantidade sem duplicação.
-   Um feedback visual ou sonoro de venda.

### Disfarce

-   Um medidor de suspeita simples.
-   Pelo menos uma ação observável que aumente a suspeita.
-   Suspeita reduzida ou estabilizada por uma condição definida.
-   Feedback visual compreensível.
-   Não é necessário criar ainda um sistema policial completo.

### Interface

-   Dinheiro atual.
-   Objetivo atual.
-   Indicador de suspeita.
-   Dica contextual de interação.
-   Layout que não cubra a área principal de jogo e seja utilizável em
    telas menores.

### Multiplayer

-   O MVP deve manter lógica crítica no servidor e ser preparado para
    vários jogadores.
-   Dois jogadores devem poder participar da mesma sessão sem duplicar
    vendas ou recompensas.
-   Se o ambiente de teste não permitir validar múltiplos clientes,
    registrar isso como pendência explícita, não como sucesso.

## 3. Fora do escopo inicial

Não implementar antes de validar o núcleo:

-   Múltiplos mapas ou cidades.
-   Árvore extensa de habilidades.
-   Economia complexa com muitas moedas.
-   Monetização, Game Passes ou Developer Products.
-   Sistema policial avançado.
-   Grandes cadeias de atividades clandestinas.
-   Customização extensa de personagens.
-   Centenas de produtos.
-   Contratação avançada de funcionários.
-   Eventos aleatórios complexos.
-   Persistência completa de toda a economia.
-   Animações cinematográficas ou assets finais que bloqueiem o
    protótipo.

Esses itens podem entrar no roadmap depois do MVP.

## 4. Critérios de sucesso

O MVP passa quando todos os itens aplicáveis forem verificados:

-   [ ] O projeto sincroniza pelo Rojo sem erros impeditivos.
-   [ ] O jogador consegue entrar e se movimentar.
-   [ ] É possível interagir com uma caixa/produto.
-   [ ] A caixa/produto pode ser transportada e colocada em local
    válido.
-   [ ] A reposição altera a quantidade de estoque.
-   [ ] Um cliente consegue alcançar a loja e comprar um produto.
-   [ ] A venda reduz o estoque e aumenta o saldo exatamente uma vez.
-   [ ] Uma venda inválida não altera saldo ou estoque.
-   [ ] Uma ação suspeita altera o medidor de suspeita de forma
    explicável.
-   [ ] A interface reflete o estado real do servidor.
-   [ ] Não há erros graves conhecidos no fluxo principal.
-   [ ] As limitações de teste manual estão documentadas.

## 5. Métricas para avaliar o protótipo

Faça testes com algumas pessoas e observe:

-   Quanto tempo levam para entender o objetivo.
-   Se conseguem realizar a primeira interação sem ajuda.
-   Se percebem quando uma venda é concluída.
-   Se entendem por que a suspeita aumenta.
-   Se a movimentação e a manipulação de objetos parecem responsivas.
-   Se conseguem imaginar jogando novamente para melhorar a loja ou
    experimentar outras ações.

Não trate números pequenos de teste como prova de viralização. Use o
feedback para encontrar confusão, frustração e partes sem graça.

## 6. Princípio de qualidade

É preferível ter uma loja pequena com um ciclo sólido, responsivo e
visualmente coerente a ter um mapa grande cheio de sistemas incompletos.

A primeira versão pode usar assets provisórios, desde que isso esteja
documentado e a arquitetura permita substituí-los sem reescrever a
lógica.
