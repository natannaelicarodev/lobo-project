# CLAUDE.md --- Regras permanentes do projeto

## 1. Missão

Desenvolver **Wolf in Sheep's Clothing**, um jogo original para Roblox
inspirado apenas em conceitos gerais de jogos de gerenciamento,
cooperação, disfarce e caos físico. O jogador é um lobo disfarçado de
ovelha que administra uma loja e tenta esconder sua verdadeira
identidade.

Use Roblox Studio, Rojo e Luau. O objetivo inicial é concluir o MVP
definido em `MVP.md`; não tente construir o jogo completo de uma só vez.

## 2. Regra principal: uma etapa por vez

-   Antes de agir, identifique a etapa atual em `README.md` e leia o
    arquivo correspondente em `etapas/`.
-   Trabalhe somente no escopo dessa etapa.
-   Não comece a etapa seguinte até cumprir os critérios de aceite da
    etapa atual.
-   Se uma etapa depender de uma decisão ou ferramenta indisponível,
    explique a limitação, escolha a alternativa mais segura e registre a
    decisão.
-   Não faça uma refatoração ampla sem necessidade.
-   Não pare após produzir um plano: implemente o que for possível na
    etapa atual.

## 3. Inspecione antes de alterar

Antes de criar, renomear, mover ou sobrescrever arquivos:

1.  Inspecione o repositório.
2.  Leia a configuração real do Rojo e os scripts relacionados.
3.  Identifique os sistemas já existentes.
4.  Preserve o trabalho válido.
5.  Verifique se a alteração realmente será sincronizada para o serviço
    Roblox esperado.

Nunca presuma que o projeto está vazio. Nunca invente APIs, assets, IDs
ou arquivos.

## 4. Honestidade sobre execução

-   Diferencie claramente código escrito, código sincronizado e código
    testado.
-   Não diga que executou o jogo se não conseguiu executá-lo.
-   Não diga que testou multiplayer se não fez um teste com múltiplos
    clientes.
-   Não diga que um modelo, som ou animação existe se ele não foi
    encontrado ou criado.
-   Se o Roblox Studio não puder ser controlado pela ferramenta
    disponível, forneça instruções manuais curtas para validar a etapa.

## 5. Padrões técnicos

-   Use Luau e APIs oficiais do Roblox.
-   Siga o padrão de nomes e a estrutura já adotados no repositório.
-   Separe lógica de servidor, lógica de cliente e módulos
    compartilhados.
-   Use `--!strict` onde for prático e compatível com o código
    existente.
-   Prefira módulos pequenos com responsabilidades claras.
-   Evite scripts gigantes, estado global desnecessário, dependências
    circulares e duplicação.
-   Centralize configurações balanceáveis em módulos de configuração.
-   Evite loops por frame quando eventos ou atualizações menos
    frequentes forem suficientes.
-   Desconecte eventos e limpe recursos quando deixarem de ser
    necessários.
-   Use nomes explícitos e comentários para explicar decisões não
    óbvias, não cada linha de código.

## 6. Segurança e autoridade do servidor

O servidor é a fonte de verdade para dinheiro, estoque, compras, vendas,
recompensas, progressão e estados importantes da partida.

-   Nunca confie em valores financeiros enviados pelo cliente.
-   Valide distância, permissões, tipo de objeto, estado da ação e
    frequência das requisições.
-   Evite compras/vendas duplicadas.
-   Proteja RemoteEvents contra parâmetros inválidos e spam.
-   Não permita que o cliente determine livremente a posição final de
    objetos importantes.
-   Não use DataStore para sincronizar movimento ou estado transitório a
    cada frame.

## 7. Assets e qualidade visual

-   Não invente IDs de meshes, imagens, animações ou sons.
-   Não dependa de assets externos sem verificar sua disponibilidade e
    permissões.
-   Geometria básica pode ser usada para prototipagem, mas identifique-a
    como provisória.
-   Não declare qualidade de modelagem profissional sem assets e
    inspeção visual que sustentem essa afirmação.
-   Estruture o projeto para permitir substituir protótipos por modelos
    personalizados depois, sem reescrever a lógica central.
-   Não copie modelos, código, sons, mapas, interface ou identidade
    visual de Shark Mart. Use-o somente como referência conceitual.

## 8. Escopo do MVP

O MVP deve provar este ciclo:

1.  O jogador entra na loja.
2.  Move-se e interage.
3.  Pega e transporta uma caixa ou produto.
4.  Reabastece uma prateleira.
5.  Um cliente NPC procura e compra um produto.
6.  O servidor valida a venda e atualiza o dinheiro.
7.  Uma ação suspeita pode aumentar a suspeita.
8.  A interface comunica dinheiro, objetivo e suspeita.
9.  O fluxo funciona sem erros graves e sem duplicar transações.

Não implemente ainda grandes expansões, múltiplos mapas, monetização,
polícia complexa, árvore extensa de upgrades ou persistência avançada, a
menos que o projeto já tenha essas bases e a etapa atual exija isso.

## 9. Fluxo de trabalho obrigatório

Para cada etapa:

1.  Leia o documento da etapa.
2.  Inspecione os arquivos relacionados.
3.  Informe um plano curto, com no máximo 5 itens.
4.  Implemente a etapa.
5.  Revise o diff e procure regressões.
6.  Execute verificações automatizadas disponíveis.
7.  Registre testes que realmente foram executados.
8.  Atualize `STATUS.md` na raiz do projeto, criando-o se necessário.
9.  Informe o que ficou pronto, o que foi testado, limitações e próximos
    passos.
10. Pare. Não inicie automaticamente a próxima etapa.

Se o projeto não estiver sob Git, não execute comandos destrutivos e
recomende criar um commit ou backup antes de alterações significativas.

## 10. Critérios para considerar algo pronto

Uma tarefa só está concluída quando: - O código está integrado ao
projeto real. - Os estados e erros relevantes são tratados. - A lógica
crítica está validada no servidor. - A etapa possui critérios de aceite
verificados ou limitações explicitamente registradas. - O estado do
projeto está documentado.

## 11. Formato de resposta ao concluir uma etapa

Use sempre:

### Implementado

-   Lista objetiva das mudanças.

### Arquivos alterados

-   Caminhos e finalidade.

### Verificações

-   Comandos/testes realmente executados e resultados.

### Validação manual pendente

-   Passos no Roblox Studio, se necessários.

### Limitações ou riscos

-   Somente os que realmente existem.

### Status

-   Etapa concluída ou bloqueada; não avance sem autorização/validação.

## 12. Instrução inicial

Comece pela **Etapa 01 --- Auditoria e base**, lendo `MVP.md` e
`etapas/01_auditoria_e_base.md`. Não implemente funcionalidades de
gameplay antes de compreender o projeto atual e a configuração Rojo.
