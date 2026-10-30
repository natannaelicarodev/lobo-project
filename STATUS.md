# Status de desenvolvimento

> Claude: atualize este documento ao concluir cada etapa. Registre
> somente o que foi realmente implementado e verificado.

## Etapa atual

-   Número: 03 --- Produtos, transporte e física
-   Estado: Concluída (aguardando validação do usuário para iniciar a Etapa 04)

## Histórico

-   Etapa 01 --- Auditoria e base: concluída. O protótipo antigo da
    padaria foi removido a pedido do usuário.
-   Etapa 02 --- Personagem e interação: concluída e aprovada. Commits
    `edf1d82` e `69c12f0`, publicados na branch
    `feat/etapa-02-personagem-interacao`.
-   Etapa 03 --- Produtos, transporte e física: concluída (seção abaixo).

## Etapa 03 --- Produtos, transporte e física

### Implementado

-   **Dados centralizados** em `src/shared/ProductConfig.luau`:
    -   Produto `Apple` (Maçã, 6 por caixa).
    -   Caixa (tamanho e cor).
    -   Prateleira (capacidade padrão 12).
    -   Depósito (4 caixas iniciais).
    -   Carregar: posição na mão, distância de soltar, sondas do raycast,
        intervalo mínimo entre pedidos, zoom da câmera e teclas G/B.
-   **`ProductService`:** cria as caixas (atributos `ProductId`, `Units`;
    tag `Interactable`, tipo `ProductBox`) nos `BoxSpawn` do
    `Workspace.Store.StockRoom`. Mostra as unidades restantes em cima da
    caixa. **Recupera caixas perdidas:** se a caixa sai do Workspace sem
    ser de propósito (por exemplo, cai do mapa), uma caixa nova com as
    mesmas unidades aparece no depósito.
-   **`CarryService`** (estratégia física):
    -   **No chão:** física simulada pelo servidor
        (`SetNetworkOwner(nil)`). O cliente não consegue mover a caixa.
    -   **Na mão:** solda com o `HumanoidRootPart`, sem colisão e sem
        massa. A tag `Interactable` é removida, então ninguém mais
        consegue pegar a mesma caixa.
    -   **Ao soltar:** o servidor escolhe a posição (3 studs à frente,
        raio contra parede, raio até o chão). O cliente só pede "soltar",
        sem mandar posição.
    -   **Morte, respawn ou saída do jogador:** a caixa é solta
        automaticamente.
    -   **Remote `RequestDrop`:** limitado por frequência.
-   **`ShelfService`:**
    -   A prateleira (BasePart com tag e `ProductId`, `Capacity`) guarda
        o atributo `Stock`.
    -   **Repor:** move `min(espaço, unidades da caixa)` da caixa na mão
        para a prateleira. Caixa vazia é descartada. A operação não tem
        `yield`, então não há duplicação mesmo com dois jogadores ao
        mesmo tempo.
    -   Recusa: sem caixa, produto diferente, prateleira cheia.
    -   Exibição provisória de uma esfera por unidade. A dica mostra
        "Prateleira de maçãs (x/12)".
-   **Handlers de interação:** `ProductBox` (pegar) e `Shelf` (repor).
-   **Cliente:**
    -   `CarryController`: soltar com G, ButtonB ou o botão "Soltar" no
        touch, só enquanto carrega. Rótulo "Carregando caixa • [G]
        soltar". A câmera aproxima (zoom máximo 10) enquanto carrega e
        volta a 20 depois.
    -   `InteractionController`: não oferece outras caixas enquanto o
        jogador carrega uma (`HideWhileCarrying`).
-   **Workspace PROVISÓRIO** `Workspace.Store`, com atributo
    `Provisional`: piso do depósito, 2 `BoxSpawn`, placa "Estoque" e a
    prateleira `AppleShelf` (bancada de madeira 6×3×2).
-   **Áudio:** não adicionado. Não há asset de som verificado no
    projeto, e IDs não são inventados.

### Testes executados (playtest pelo MCP, 1 jogador)

-   `rojo build` com exit 0. Sync: todos os scripts com o mesmo tamanho
    dos arquivos.
-   **Início:** 4 caixas criadas com 6 unidades, `NetworkOwner = nil`
    (servidor).
-   **Validações:**
    -   Soltar sem carregar → recusado ("Você não está carregando
        nada").
    -   Pegar caixa perto → `Ok`, `CarryingBox = true`, `CarriedBy`
        definido.
    -   Pegar de novo a caixa que está na mão e dois pedidos seguidos →
        `Invalid` (a tag foi removida). **Sem duplicação.**
    -   Repor com a prateleira cheia → recusado.
-   **Reposição parcial:** confirmada pelo estado do jogo. Uma caixa
    ficou com 2 unidades depois que o usuário, jogando ao mesmo tempo,
    repôs 4 numa prateleira com 8.
-   **Recuperação:** uma caixa com 2 unidades foi jogada abaixo de
    `FallenPartsDestroyHeight`. Ela foi destruída e uma nova com 2
    unidades apareceu no depósito (aviso esperado no log).
-   **Morte carregando:** a caixa foi solta 3 studs à frente da posição
    da morte, voltou a ter a tag e ficou sem `CarriedBy`.
    `CarryingBox = false`.
-   **Output:** só o aviso esperado da recuperação. Nenhum erro no
    servidor ou no cliente.

### Limitações e riscos

-   **Testes perturbados:** parte deles foi feita com o usuário jogando
    no mesmo playtest, o que causou `OutOfRange` e `TooFast` em alguns
    passos. Os casos principais foram confirmados depois, ou pelo estado
    final do jogo.
-   **Sem animação de segurar:** os braços não seguram a caixa (exigiria
    uma animação; nenhum ID é inventado).
-   ~~Caixa em cima de superfícies~~: corrigido (ver "Correção:
    soltar perto da bancada" abaixo).
-   **Estoque finito:** o estoque do depósito é finito (4 caixas). A
    compra ou entrega de caixas vem com a economia (Etapa 04 ou depois).
-   **Visuais provisórios:** caixa, maçãs e prateleira usam peças
    simples.
-   **Multiplayer:** ainda não testado com 2 clientes (Etapa 06).

### Correção: soltar perto da bancada (validação manual da Etapa 03)

-   **Problemas encontrados no código anterior** (`findDropCFrame`):
    1.  Colado na bancada, o raio frontal batia nela a menos de 1,6 stud,
        a distância virava 0 e a caixa era colocada **na posição do
        próprio jogador**, e a física empurrava os dois.
    2.  Só o centro da caixa era checado. Uma caixa de 2,2 de largura
        podia ficar meio dentro da bancada, ou o raio do chão, que
        começava 6 studs acima, pousava **em cima** da bancada.
    3.  Começar o raio do chão 6 studs acima poria a caixa num teto
        quando a loja tiver teto.
-   **Correção** (só em `CarryService` e `ProductConfig.Carry`, sem
    mudar as outras funções):
    -   O servidor testa, em ordem, pontos a 3, 2,5 e 2 studs à frente e
        nas diagonais de ±30° (`DropDistances` e `DropAngles`).
    -   Um ponto só é aceito se tiver:
        -   chão plano encontrado por um raio que **começa na altura do
            jogador** (`DropMaxStepDown`, `DropMinFloorNormalY`) e que
            **não é objeto interativo** (bancada, caixa);
        -   linha livre do jogador até o ponto (não atravessa parede);
        -   volume da caixa sem tocar nada sólido (`GetPartBoundsInBox`,
            respeitando `CanCollide`, incluindo outros jogadores e
            caixas).
    -   Se nenhum ponto servir, **o pedido é recusado** ("Sem espaço para
        soltar aqui...") e a caixa continua na mão.
    -   **Morte, respawn ou saída** (`drop(player, true)`): tenta os
        mesmos pontos e, se não houver, coloca a caixa no chão onde o
        jogador estava.
    -   **Autoridade do servidor mantida:** o cliente continua mandando só
        o pedido `RequestDrop`, sem nenhum dado. A posição é calculada
        apenas no servidor.
-   **Testado no playtest** (raiz do personagem ancorada pelo servidor
    em posições fixas, para o teste não depender do controle do
    jogador):
    1.  Colado na bancada (1,2 stud), de frente, raiz a 2,6 → `Rejected`
        com a mensagem, a caixa continua na mão. Também recusou com a
        raiz a 5,3 de altura (o chão encontrado era o topo da bancada,
        interativo).
    2.  Mesmo lugar, de costas para a bancada → `Ok`. A caixa ficou a 3
        studs, no chão (y = 0,58), sem tocar em nada, com física do
        servidor.
    3.  Morte colado na bancada carregando caixa → caixa no chão onde o
        jogador estava, sem tocar a bancada nem ficar em cima dela.
        Encosta só no corpo do personagem morto, que some no respawn. A
        caixa voltou a ser interativa.
    4.  Output do servidor e do cliente sem erros.
-   **Ainda depende de validação manual:**
    -   Soltar com G em situações reais: perto da bancada, de lado para
        ela, em cantos e perto das caixas do depósito. Conferir se a
        recusa não acontece demais em lugares onde deveria caber.
    -   Soltar com outro jogador na frente (sem teste multiplayer
        disponível).

### Animações de carregar (pedido extra antes da Etapa 04)

-   **Rig analisado:** R15 com 15 `AnimationConstraint` de nomes padrão
    (`Root`, `Waist`, `Neck`, `Right/LeftShoulder`, `Elbow`, `Wrist`,
    `Hip`, `Knee`, `Ankle`). Pose de descanso em T. Eixos das
    articulações = eixos do mundo (X direita, Y cima, −Z frente). A
    malha, as texturas e a aparência não foram alteradas.
-   **Animações criadas** (`KeyframeSequence`, autoria própria, sem
    terceiros) pelo script `tools/animations/build_carry_animations.luau`:

    | Nome | Uso | Loop | Prioridade | Duração |
    |---|---|---|---|---|
    | `CarryIdle` | parado carregando (braços sob a caixa, tronco levemente para trás, respiração) | sim | Action | 2,0 s |
    | `CarryWalk` | andando carregando (passada curta, quadril balançando, braços fixos) | sim | Action | 0,9 s |
    | `PickUp` | agacha, segura e levanta | não | Action2 | 1,0 s |
    | `PlaceBox` | inclina e estende os braços para a prateleira | não | Action2 | 0,9 s |

    -   Todas as articulações recebem pose em todos os keyframes. Assim,
        enquanto tocam, elas **substituem por completo** a animação
        padrão (sem membros misturados).
    -   As duas animações únicas (Action2) tocam por cima das de
        carregar e depois devolvem o controle a elas.
-   **Onde ficam:**
    -   `ReplicatedStorage.AnimationSources`: cópias para pré-visualização
        no Studio.
    -   `Workspace.AnimationRig_Wolf.AnimSaves`: para abrir e publicar no
        Animation Editor. O `AnimationRig_Wolf` é uma cópia do
        personagem, com atributo `Provisional`, e não é jogável.
-   **Código:**
    -   `src/shared/AnimationConfig.luau`: ID, prioridade, loop e fade de
        cada animação. Os IDs estão **vazios** até a publicação.
    -   `src/client/Controllers/CharacterAnimationController.luau`:
        carregando e andando → `CarryWalk`; carregando e parado →
        `CarryIdle`; pegar ou repor aceito pelo servidor → `PickUp` ou
        `PlaceBox` uma vez. Usa eventos (atributo `CarryingBox`,
        `Humanoid.Running`), sem loop por frame. As conexões são limpas
        a cada respawn.
    -   `InteractionController`: só ganhou o sinal `Succeeded`, disparado
        depois da resposta positiva do servidor. O resto não mudou.
    -   `ProductConfig.Carry.HoldOffset`: de `(0, −0.4, −2.2)` para
        `(0, 0.1, −1.6)`, para a caixa ficar sobre as mãos (os braços do
        modelo são curtos). Valor visual; a mecânica da Etapa 03 não
        mudou.
    -   **Sem ID publicado:** no Studio, o controlador registra
        animações temporárias a partir de `AnimationSources`
        (`KeyframeSequenceProvider:RegisterKeyframeSequence`). Fora do
        Studio, sem ID, a animação é ignorada com um aviso no Output.
-   **Testado no playtest (fluxo real, tecla E):**
    1.  Pegar caixa → `PickUp` (Action2) por cima de `CarryIdle`
        (Action), depois só `CarryIdle`.
    2.  Andar carregando → transição para `CarryWalk`. Parar → volta a
        `CarryIdle`.
    3.  Repor na prateleira (com o estoque baixado para 4 pelo servidor)
        → `PlaceBox`. A caixa esvaziou (+6, 10/12) e as animações de
        carregar pararam, sem nada sobrando.
    4.  Prateleira cheia (12/12): a reposição é recusada e nenhuma
        animação toca (só toca com sucesso).
    5.  Output do servidor e do cliente sem erros.
    6.  Antes, com a pose aplicada e uma caixa real: as mãos ficam sob a
        caixa, à frente do corpo (print de lado conferido).

### Animações publicadas

-   O usuário publicou as 4 animações ("Salvar no Roblox" no Explorador).
    IDs colocados em `AnimationConfig.luau`:
    -   `CarryIdle` = `rbxassetid://95929208934414`
    -   `CarryWalk` = `rbxassetid://134787024206171`
    -   `PickUp` = `rbxassetid://111667969637663` (versão que começa
        agachada, duração 0,75 s)
    -   `PlaceBox` = `rbxassetid://84980375964126`
-   Tentativa de publicar pelo MCP: `AssetService:CreateAssetAsync`
    respondeu "not available yet". Por isso a publicação foi manual.
-   **Testado no playtest com os IDs publicados:**
    -   As 4 carregam (duração 2,0 / 0,9 / 0,75 / 0,9 s).
    -   O controlador toca os IDs publicados, não as cópias temporárias.
    -   Pegar (E): `PickUp` + `CarryIdle`.
    -   Andar: `CarryWalk` a 16 de velocidade; parar: `CarryIdle`.
    -   Repor (E): `PlaceBox`, "+6 maçãs (8/12)", e a caixa vazia foi
        descartada.
    -   Output do servidor e do cliente sem erros.
-   `AnimationRig_Wolf` movido do Workspace para o `ServerStorage`, para
    não aparecer no jogo. Para editar uma animação, traga ele de volta
    ao Workspace, abra no Animation Editor e publique de novo (o ID muda
    se for publicado como asset novo).
-   `ReplicatedStorage.AnimationSources` ficou só como pré-visualização,
    caso algum ID volte a ficar vazio. Com os IDs preenchidos, não é
    usado.

### Ação manual necessária: publicar as animações (FEITO)

IDs temporários só funcionam no Studio. Para funcionar no jogo publicado:

1.  No Studio, aba **Avatar → Animation Editor** (ou Plugins → Animation
    Editor).
2.  Clique no rig **`AnimationRig_Wolf`** no Workspace.
3.  No editor, clique em **⋯ → Load**, escolha `CarryIdle` e ajuste se
    quiser.
4.  **⋯ → Publish to Roblox**. Dê o nome (por exemplo, "Wolf CarryIdle"),
    publique como **você** (o mesmo dono da experiência) e copie o ID
    que aparecer.
5.  Repita para `CarryWalk`, `PickUp` e `PlaceBox`.
6.  Me envie os 4 IDs. Eu coloco em `AnimationConfig.luau` e testo de
    novo. Antes de colar, confira no editor se o Loop e a prioridade
    continuam como na tabela acima.
7.  Depois de publicar, o `AnimationRig_Wolf` pode sair do Workspace
    (mover para `ServerStorage` ou apagar).

### Pendências e limitações das animações

-   ~~Sem IDs publicados~~: publicados (ver acima).
-   **Poses feitas por código:** foram conferidas por números e por um
    print da pose parada. `CarryWalk`, `PickUp` e `PlaceBox` **não
    foram conferidos visualmente em movimento** (a captura de tela não
    pega animação). Pode haver deslize de pé ao agachar no `PickUp`.
    Ajuste fino recomendado no Animation Editor.
-   ~~Caixa parada durante o `PickUp`~~: **corrigido** (relato do
    usuário: o personagem abaixava, mas a caixa ficava parada na posição
    final).
    -   Causa: a caixa estava soldada ao `HumanoidRootPart`, que não se
        move com as animações.
    -   Correção: o servidor solda a caixa à **mão direita** com um `Weld`
        de deslocamento fixo (`ProductConfig.Carry.HoldPart` e
        `HoldOffsetFromPart`). O deslocamento foi medido na pose
        `CarryIdle`, de modo que, segurando, a caixa fica exatamente no
        `HoldOffset`. Se a mão não existir, volta para a solda na raiz.
    -   O `PickUp` agora **começa agachado** (keyframes 0 e 0,2 s
        agachado, 0,75 s segurando; fade de entrada 0,25 s). Assim a mão,
        e a caixa junto, começa perto do chão e sobe.
    -   A autoridade continua no servidor (solda e deslocamento definidos
        só nele). Soltar, repor e a posição de soltura (calculada pela
        raiz) não mudaram.
    -   **Testado no playtest com a tecla E:** altura da caixa em relação
        à raiz −1,37 → −2,22 (fundo do agachamento, junto ao chão) →
        +0,05 em 0,6 s → +0,10/−1,60 estável (= `HoldOffset`).
        - Soltar com G colado às caixas do depósito → recusado ("Sem
          espaço...").
        - Virado para o chão livre → `Ok`. A caixa ficou no chão, sem
          solda, com física do servidor e interativa.
        - Output sem erros.
    -   Detalhe que sobrou: no fundo do agachamento, a caixa afunda cerca
        de 0,2 stud no chão por um instante (ajuste fino no Animation
        Editor, no keyframe `CROUCH`).
-   **Pulo carregando:** as poses de carregar continuam no ar (as pernas
    não fazem a pose de pulo).
-   Ao repor e esvaziar a caixa, o `PlaceBox` termina sem a caixa (ela
    some na hora).

### Caixa de maçãs definitiva (modelo da Loja do Criador)

-   O usuário inseriu pela Loja do Criador um modelo de caixa de madeira
    com maçãs.
-   **Verificado antes de usar:**
    -   **Nenhum script** no modelo.
    -   43 peças: tábuas, cunhas e 18 maçãs.
    -   As maçãs usam a malha clássica do catálogo da Roblox (`id=16190555`
        e textura `16190577`), que veio junto com o modelo.
-   **Preparado como molde** em `ServerStorage.ProductTemplates.Apple`:
    -   Reduzido pelo fator 0,572: de 3,85 × 2,62 × 3,04 para
        **2,2 × 1,5 × 1,74** (as malhas das maçãs foram escaladas junto).
    -   As 18 maçãs foram marcadas com o atributo `ProductUnit` (1 a 6,
        três maçãs por unidade). As de baixo são a unidade 1 e saem por
        último.
-   **Código:**
    -   `ProductService` monta a caixa a partir do molde, se ele existir.
        Uma peça invisível `Crate` do tamanho do molde faz toda a física
        (colisão, solda na mão, cálculo de soltura). As tábuas e maçãs
        são só visuais (sem colisão, sem massa, soldadas). Sem molde,
        volta para a caixa provisória.
    -   `ProductConfig.Box.Size` = (2,2; 1,5; 1,74), para combinar com o
        molde (empilhamento no depósito e reserva).
    -   `HoldOffset` = (0; 0,25; −1,65) e `HoldOffsetFromPart` remedido
        na pose `CarryIdle`, para a caixa mais alta e mais funda ficar
        apoiada nas mãos.
-   **Testado no playtest:**
    -   4 caixas criadas a partir do molde, com 18 maçãs visíveis cada e
        empilhadas sem sobreposição (y = 0,74 e 2,19).
    -   Pegar com E (com animação), carregar e ver de lado e de cima: a
        caixa fica nas mãos, à frente do corpo.
    -   Reposição parcial: prateleira 9 → 12, +3. A caixa ficou com 3
        unidades e **9 maçãs visíveis**.
    -   Soltar com G em área livre → caixa no chão (y = 0,74, base no
        chão).
    -   Output sem erros.
-   **Prateleira com a mesma maçã:** `ShelfService` agora mostra cada
    unidade com uma cópia da maçã do molde (`ProductService.getUnitModel`,
    a primeira peça com `ProductUnit`), em pé, com a rotação original da
    malha. Sem molde, volta para as esferas provisórias.
    -   Testado no playtest: pegar e repor → "+6 maçãs (6/12)". 6 unidades
        na bancada, com a malha `id=16190555` (0,67 × 0,64 × 0,62). Print
        conferido. Output sem erros.
-   **Pendência:** salvar em arquivo para o molde entrar no
    `lobo-project.rbxl`.

### Expositor de maçãs definitivo (Loja do Criador, asset 10655743934)

-   **Verificado em quarentena** (`ServerStorage.Quarantine`, onde
    scripts não rodam):
    -   **Nenhum script.**
    -   64 maçãs (MeshPart com a malha `6736431944`), tábuas e uma placa
        com imagem `177575747` e o texto "Apples - 5R$".
    -   Uma `ThumbnailCamera`, removida.
-   **Ajustes:**
    -   Escalado para **0,65**: de 8,1 × 9,5 × 3 para 5,26 × 6,18 × 1,95.
        O original tinha quase o dobro da altura do lobo.
    -   Texto da placa trocado para **"Maçãs"**. O preço sai até existir
        economia; "5R$" não era do jogo.
    -   Substituiu a bancada provisória no mesmo lugar (20, −6).
-   **Estrutura:** `Workspace.Store.Shelves.AppleShelf` é uma peça
    invisível do tamanho do expositor (tag `Interactable`, `Shelf`,
    `ProductId = Apple`, `Capacity = 12`, com colisão). O modelo fica
    dentro dela como `Visual` (sem colisão nem consulta). As maçãs
    receberam `DisplayUnit` (substituído depois pelos `DisplaySlot`, ver
    abaixo).
-   **Código (versão final, a pedido do usuário: "quantidade exata, não
    um amontoado"):**
    -   As 64 maçãs amontoadas do modelo foram **removidas**.
    -   A prateleira tem 12 Attachments `DisplaySlot` (atributo `Order`),
        6 por andar, em fila, sobre o piso de cada andar (Y 2,05 e 3,67;
        X de 17,9 a 21,8; Z −5,96). Dá para ajustar movendo os
        Attachments no Studio.
    -   `ShelfService` coloca **exatamente uma maçã por unidade em
        estoque** (a maçã do molde da caixa), da posição 1 em diante.
        Prateleiras sem `DisplaySlot` usam uma grade sobre o topo.
    -   O modo proporcional (`DisplayUnit`) foi removido do código.
    -   Testado: 0/12 → 0 maçãs; 6/12 → 6 maçãs no andar de baixo;
        12/12 → 12 maçãs (6 + 6). Prints conferidos, Output sem erros.
    -   Bug encontrado e corrigido no teste: as posições foram criadas
        com `WorldPosition` antes de estarem presas à prateleira e
        viraram deslocamento relativo (as maçãs apareceram longe). Foram
        convertidas para coordenadas do mundo.
-   **Testado no playtest:**
    -   Início 0/12 → 0 maçãs visíveis.
    -   A dica mira a prateleira ("Repor maçãs").
    -   Repor → 6/12 → 32 maçãs (andar de baixo cheio).
    -   Repor de novo → 12/12 → 64 maçãs.
    -   Prints conferidos. Output do servidor e do cliente sem erros.
-   **A cópia de quarentena foi apagada.** O expositor em uso fica na
    loja.
-   **Pendências:**
    -   ~~Placa de costas~~: **corrigido**. O expositor estava de costas
        para a loja. O `Visual` foi girado 180° em torno do centro da
        prateleira (mesmo lugar), e a ordem `DisplayUnit` foi refeita
        (andar de baixo, depois da frente, lado +Z, para trás). Print
        no playtest: placa "Maçãs" com a imagem da maçã de frente e as
        maçãs expostas para o lado do lobo. Reposição 6/12 ok.
    -   A colisão é uma caixa inteira, então não dá para passar entre as
        pernas do expositor.
    -   Salvar em arquivo para entrar no `lobo-project.rbxl`.

### Teste manual sugerido

1.  Jogue (F5) e vá até o piso "Estoque".
2.  Aperte E numa caixa. Aparece "Carregando caixa" e a câmera
    aproxima.
3.  Vá até a bancada e aperte E. As maçãs aparecem na prateleira e a
    caixa esvazia ou some.
4.  Pegue outra caixa e aperte G. Ela cai à sua frente.
5.  Tente pegar uma segunda caixa com a primeira na mão. Ela não é
    oferecida.

## Estado do projeto

### Configuração Rojo

-   Rojo 7.7.1, fixado em `aftman.toml`. Projeto: `default.project.json`.
-   Mapeamento:

    | Pasta         | Serviço no Roblox                           | Tipo da raiz |
    |---------------|---------------------------------------------|--------------|
    | `src/server`  | `ServerScriptService.Server`                | `Script`     |
    | `src/client`  | `StarterPlayer.StarterPlayerScripts.Client` | `LocalScript`|
    | `src/shared`  | `ReplicatedStorage.Shared`                  | `Folder`     |

-   Subpastas dentro de `src/server` e `src/client` viram `Folder`, e os
    arquivos viram ModuleScripts filhos do script raiz. Exemplo:
    `require(script.Services.InteractionService)`.
-   **Mudança na Etapa 02:** `StarterPlayer.$properties.LoadCharacterAppearance = false`.
    Motivo: todos os jogadores começam com o mesmo corpo simples, e a
    fantasia de ovelha não briga com roupas e acessórios do avatar.
    Fica versionado em texto, em vez de ficar escondido no `.rbxl`.

### Arquitetura

```
src/shared/
  InteractionConfig.luau  valores de interação, tipos de objeto e mensagens (PT-BR)
  Interactable.luau       leitura dos dados de um objeto interativo (cliente e servidor)
  Remotes.luau            nomes e criação/busca dos remotes
  CharacterConfig.luau    peças da fantasia provisória e cor de lobo
src/server/
  init.server.luau        bootstrap: registra handlers e inicia serviços
  Services/InteractionService.luau  autoridade do servidor sobre interações
  Services/CharacterService.luau    aplica a fantasia em cada personagem
  Interactions/LightSwitch.luau     handler: acende/apaga lâmpada ligada por ObjectValue "Lamp"
  Interactions/Door.luau            handler: abre/fecha porta
  Interactions/Sign.luau            handler: mostra o atributo "Message"
src/client/
  init.client.luau        bootstrap
  Controllers/InteractionController.luau  alvo mais próximo, entrada, envio ao servidor
  UI/InteractionHint.luau  dica contextual (BillboardGui) acima do objeto
  UI/FeedbackToast.luau    aviso verde (sucesso) ou vermelho (recusa)
```

### Sistema de interação

-   **Como marcar um objeto:** coloque a tag `Interactable` (CollectionService)
    num `BasePart` ou `Model` do Workspace e defina o atributo
    `InteractionType` com uma chave de `InteractionConfig.Types`.
-   **Atributos opcionais:** `Enabled` (false = trancado), `DisabledMessage`,
    `ActionText`, `ObjectText` e `MaxDistance`.
-   **Novo tipo de objeto:** adicione a entrada em `InteractionConfig.Types`
    e crie um módulo em `src/server/Interactions/` com
    `{ TypeName, interact(player, target) -> (ok, message?) }`.
    O bootstrap registra o módulo sozinho.
-   **Cliente:** a cada 0,1 s procura o objeto válido mais próximo dentro do
    alcance. Não há loop por frame. Mostra a dica e liga a tecla E
    (teclado), X (gamepad) e um botão "Usar" (touch) **só enquanto existe
    um alvo**. Envia `RequestInteraction` (RemoteFunction) e mostra o
    resultado que o servidor devolveu.
-   **Servidor:** valida, nesta ordem:
    1.  Tipo do argumento, tag e presença no Workspace (`Invalid`).
    2.  Frequência: no mínimo 0,25 s entre pedidos (`TooFast`).
    3.  Handler registrado para o tipo (`Invalid`).
    4.  Personagem vivo (`NoCharacter`).
    5.  Distância: alcance + 3 studs de tolerância (`OutOfRange`).
    6.  `Enabled` (`Disabled`, com mensagem própria).
    7.  Trava por objeto (`Busy`).
    -   Depois roda o handler protegido por `pcall` (`Failed` em caso de erro).

### Personagem

-   Movimento: controles padrão do Roblox (teclado, gamepad e touch). Sem
    controlador próprio.
-   **Visual atual (INTERMEDIÁRIO, não final):** modelo próprio gerado com
    a IA do Roblox Studio e rigado como avatar R15:
    -   Origem: `generate_mesh` (malha v2) → `generate_texture` (v4) →
        `auto_setup_avatar` (Development).
    -   Instalado como `StarterPlayer.StarterCharacter`, com os atributos
        `CharacterModel = "WolfDisguise_v4"` e `Provisional = true`.
    -   O script de animação gerado foi renomeado para `Animate`. Assim o
        Roblox não injeta um segundo Animate padrão.
    -   Nenhum ID de asset foi escrito à mão: malha e textura foram criadas
        pela geração dentro do place publicado.
-   **Arquivos de origem** (todas as tentativas, v1 a v5, e o rig):
    `ServerStorage.DevCharacterSources`. Podem ser apagados quando
    houver modelo final.
-   **Reserva:** se o `StarterCharacter` não existir (por exemplo, num
    place montado só com `rojo build`), o `CharacterService` aplica a
    fantasia antiga de esferas (`CharacterConfig.Costume`). Com o modelo
    presente (atributo `CharacterModel`), o serviço não faz nada.
-   O sistema de interação não foi alterado.
-   **Por que não usar peças/esferas:** sem malha esculpida e textura não
    há como fazer o rosto (olhos, dentes, focinho), a lã com volume e
    textura, nem uma roupa integrada ao corpo. A montagem com esferas foi
    rejeitada na validação visual.

### Área de teste PROVISÓRIA (Workspace, salva no .rbxl)

-   `Workspace.DevInteractionTest`, com o atributo `Provisional = true`:
    -   Interruptor amarelo com lâmpada num poste.
    -   Placa de teste.
    -   Porta do estoque trancada (`Enabled = false`).
-   Serve só para validar a mecânica. Deve ser removida ou substituída
    quando a loja for construída.

### Ferramentas de teste disponíveis

-   `rojo build` / `rojo sourcemap` (`~/.aftman/bin/rojo.exe`).
-   `rojo serve` pela extensão do VS Code `evaera.vscode-rojo`, com o
    plugin do Studio conectado.
-   MCP `Roblox_Studio`: roda Luau no Edit, Server e Client, inicia e
    para o playtest, lê logs, envia teclas e captura a tela.
-   Não instalados: `selene`, `stylua`, `luau-lsp`. Não há lint nem
    verificação de tipos `--!strict` automatizada.
-   Não disponível: teste com múltiplos clientes.

## Como sincronizar e testar

1.  Abra `lobo-project.rbxl` no Studio.
2.  Inicie o Rojo no VS Code (extensão Rojo → *Start server*) ou rode
    `~/.aftman/bin/rojo.exe serve default.project.json`.
3.  No plugin Rojo do Studio, clique em **Connect**.
4.  Rode o playtest (F5) e confira o Output.
5.  Checagem sem Studio: `~/.aftman/bin/rojo.exe build default.project.json -o build.rbxl`.

## Implementado (Etapa 02)

-   Sistema de interação reutilizável: tag + atributos, validação no
    servidor, dica contextual, aviso de feedback e suporte a teclado,
    gamepad e touch.
-   Três tipos de interação: interruptor de luz, porta e placa.
-   Fantasia provisória de lobo disfarçado de ovelha, aplicada a cada
    spawn.
-   Área de teste provisória no Workspace.
-   Removido `src/shared/Hello.luau`, o módulo do template.

## Arquivos criados e modificados (Etapa 02)

-   Criados:
    -   `src/shared/InteractionConfig.luau`, `Interactable.luau`,
        `Remotes.luau` e `CharacterConfig.luau`.
    -   `src/server/Services/InteractionService.luau` e
        `CharacterService.luau`.
    -   `src/server/Interactions/LightSwitch.luau`, `Door.luau` e
        `Sign.luau`.
    -   `src/client/Controllers/InteractionController.luau`.
    -   `src/client/UI/InteractionHint.luau` e `FeedbackToast.luau`.
-   Modificados: `src/server/init.server.luau`,
    `src/client/init.client.luau`, `default.project.json` e este arquivo.
-   Removido: `src/shared/Hello.luau`.

## Testes executados (Etapa 02)

-   `rojo build default.project.json` → sucesso (exit 0).
-   `rojo sourcemap` → a árvore confere com o esperado (Shared com 4
    módulos; Server com Interactions/3 e Services/2; Client com
    Controllers/1 e UI/2).
-   Sincronização: o tamanho do `Source` de todos os scripts no Studio
    confere com os arquivos locais. `LoadCharacterAppearance = false`
    chegou ao Studio.
-   Playtest pelo MCP (1 jogador), chamando o remote a partir do cliente:
    -   Interruptor dentro do alcance → `Ok`, "Luz acesa." A luz ligou e o
        texto mudou para "Apagar luz". Segunda vez → "Luz apagada."
    -   Porta longe → `OutOfRange`.
    -   Baseplate (sem tag), string e nil → `Invalid`.
    -   Dois pedidos seguidos → primeiro `Ok`, segundo `TooFast`.
    -   Porta trancada dentro do alcance → `Disabled`, "A porta do estoque
        está trancada."
-   Dica contextual:
    -   Aparece no objeto certo ("Acender luz"; "Porta do estoque •
        indisponível").
    -   Some quando o jogador se afasta de tudo.
    -   Some na hora da morte.
    -   Sem alvo, a ação "Interact" fica desligada (a tecla E fica livre).
-   Fantasia: as 10 peças são criadas e o corpo fica cinza. Depois de um
    respawn forçado (`LoadCharacter`), o personagem novo recebe a
    fantasia de novo.
-   Bug encontrado e corrigido: a fantasia não aparecia porque o código
    abortava quando o personagem ainda não tinha pai no `CharacterAdded`
    (comportamento normal do Roblox) e esperava `Torso` em vez de
    `UpperTorso`.
-   Output: nenhum erro ou aviso dos scripts do projeto.

## Correção visual do personagem (Etapa 02, revisão)

-   Motivo: a fantasia de esferas foi reprovada pelo usuário (cabeça
    desproporcional, rosto invisível, peças sobrepostas).
-   Bloqueio encontrado e resolvido: a geração por IA falhava com
    "Unauthorized" e "User is not authenticated". O usuário refez o login
    no Studio e publicou a experiência (privada, sem Criação em equipe).
    Place: `placeId 71138535420331`, `gameId 10773842012`.
-   Geradas 5 versões (detalhes em `ServerStorage.DevCharacterSources`):
    -   v1: lã bonita, mas braços colados e cauda arrastando no chão.
    -   v2: pose em T e rosto bom, mas a nuca é cinza.
    -   v3: retextura da v2 com as costas certas e o rosto estragado.
    -   v4: retextura da v2 com a melhor frente e as costas cinza.
    -   v5: muita lã, mas braços curtos e ruins para rigar.
-   Escolhida a v4, rigada como R15.
-   Mudança de código: `CharacterService` agora pula o personagem que tem
    o atributo `CharacterModel`; `CharacterConfig.CustomModelAttribute`.
-   Testes executados (playtest pelo MCP):
    -   `rojo build` com exit 0. Sync confere (tamanhos idênticos).
    -   Personagem nasce com `CharacterModel = WolfDisguise_v4`, R15,
        Health 100, um único `Animate` e sem a fantasia de esferas.
    -   Andou até o interruptor com `Humanoid:MoveTo` (alvo alcançado).
        Animações de andar e correr rodaram. Interação → `Ok`.
    -   Parado no chão: pés em Y = 0,05 (sem afundar nem flutuar).
    -   Prints de frente, de lado e de costas tirados no playtest.
    -   Respawn (Health = 0) recria o mesmo modelo, sem a fantasia de
        reserva.
    -   Output do servidor e do cliente: nenhum erro ou aviso. Os erros
        de asset e autenticação também sumiram depois do novo login.
-   **Limitações do modelo atual:**
    -   As costas não têm fantasia: nuca e costas são cinza (corpo de
        lobo). O conceito pede lã nas costas.
    -   A cauda foi incluída na perna esquerda pelo rig automático, então
        balança junto com essa perna ao andar.
    -   As mangas ficaram cinza em vez de lã.
    -   A qualidade da geração por IA varia e a malha é única, sem
        separação entre roupa e corpo.
-   **Solução definitiva recomendada:** modelar no Blender com corpo de
    lobo, fantasia como malha própria (capuz, macacão de lã, orelhas) e
    cauda num osso próprio. Depois, importar pelo Avatar Setup e trocar o
    `StarterCharacter`. Nenhum código precisa mudar.

## Personagem Meshy (substitui a v4)

-   O usuário gerou o modelo no Meshy (plano Pro, licença Privado):
    Multi-View, pose em T, remesh para menos de 20 mil faces e envio pelo
    Send to Roblox. Asset `82876829426923`, inserido pelo MCP.
-   O modelo chegou com 1,9 stud de altura; foi escalado para 5 studs e
    rigado como R15 com `auto_setup_avatar` (Development). Instalado
    como `StarterPlayer.StarterCharacter`, com
    `CharacterModel = "WolfMeshy_v1"`.
-   A v4 antiga foi guardada em `ServerStorage.DevCharacterSources`.
-   Problemas encontrados e corrigidos:
    1.  **Personagem cinza no jogo:** o rig perdeu o `ColorMap` da
        `SurfaceAppearance`. Os mapas originais do Meshy (cor, normal,
        rugosidade e metal) foram reaplicados nas 15 partes. O UV foi
        mantido, então a textura encaixa.
    2.  **Furos no capuz e no rosto**, com o céu aparecendo através
        (relatado pelo usuário): `RenderFidelity = Precise` (sem a malha
        simplificada automática) e `DoubleSided = true` (desenha o lado
        de dentro do capuz) em todas as MeshParts. Depois disso o close
        no jogo não mostrou mais furos.
-   Testado no playtest:
    -   Frente, lado e costas com textura (lã nas costas, cauda escura
        visível).
    -   Andando com animação de corrida.
    -   Interação com o interruptor → `Ok`.
    -   Respawn recria o mesmo modelo com `Precise`.
    -   Output do servidor e do cliente sem erros.
    3.  **Linhas brancas e rachaduras no rosto, só no jogo** (relatado
        pelo usuário mesmo depois do item 2): a causa era o `FaceControls`
        (cabeça dinâmica) que o `auto_setup_avatar` cria na Head. A
        animação facial deforma a malha e separa os vértices nas emendas
        de UV, e por essas frestas aparece o branco do capuz.
        -   Diagnóstico: uma cópia sem Humanoid ficou limpa. Ao remover o
            `FaceControls` ao vivo no playtest, as linhas sumiram.
        -   Correção: `FaceControls` removido do `StarterCharacter` e do
            rig de origem. O personagem não usa expressões faciais.
        -   Mapas finais: cor, normal e rugosidade originais do Meshy,
            sem mapa de metal (lã e pelo não são metálicos).
        -   Verificado com close no jogo: rosto sem linhas e Output sem
            erros.
        -   **Regra para futuros modelos** rigados com `auto_setup_avatar`:
            remover o `FaceControls` se o modelo não tiver a cabeça
            preparada para expressões faciais.
    4.  **Lã "estilhaçada" e linhas escuras na nuca, só no jogo**
        (relatado pelo usuário): NÃO resolvido dentro do Studio.
        -   Diagnóstico: o rig não usa ossos (peças rígidas com
            `AnimationConstraint`), então não é deformação. Um segundo rig
            com `enable_additional_head_processing = false` ficou igual.
        -   O modelo original do Meshy parece liso no Edit, onde a
            qualidade gráfica é alta e o mapa de normal disfarça a malha.
        -   No jogo (qualidade automática) aparecem as faces chapadas do
            remesh (normais facetadas) e o vazamento de cor nas bordas das
            ilhas de UV.
        -   **Resolvido com limpeza no Blender 5.2** (script
            `tools/blender/clean_meshy_character.py`, rodado em modo
            headless):
            -   O GLB do Meshy tinha 24.212 bordas abertas (triângulos
                soltos), que eram as frestas. Depois de soldar vértices
                (0,5 mm) sobraram 9.
            -   Normais suavizadas por ângulo (50°).
            -   Textura de cor refeita em 2048 px com margem de 24 px nas
                bordas das ilhas de UV.
            -   19.800 triângulos.
            -   Saída: `Desktop\lobo-art\wolf_clean.glb`, fora do Git.
                Importado no Studio pelo usuário (Importar 3D, sem rig).
        -   Rigado de novo (`auto_setup_avatar`, Development, sem head
            processing). `FaceControls` removido, `Precise` e
            `DoubleSided` ativos, textura limpa no `ColorMap`, sem mapas
            de normal, rugosidade ou metal.
        -   Instalado como `StarterCharacter`
            (`CharacterModel = "WolfMeshy_clean_v1"`). A versão anterior
            está em `ServerStorage.DevCharacterSources`.
        -   Verificado no jogo (qualidade automática):
            -   Close da nuca sem cortes e lã sólida.
            -   Close do rosto limpo.
            -   Andar, respawn (sem `FaceControls`) e interação a 3,7
                studs (`Ok`).
            -   Output do servidor e do cliente sem erros.
        -   Para gerar o preview: `tools/blender/preview_glb.py`.
        -   **Ajuste depois do relato de linhas nos cantos dos olhos:**
            `DoubleSided` foi desligado de novo. Com a malha soldada ele
            não é mais necessário, e nas dobras finas (cantos dos olhos)
            mostrava o lado de dentro das faces. Renders no Blender do GLB
            original e do limpo mostram os olhos sem defeito, então o
            problema estava na renderização do Roblox. Close no jogo com
            `DoubleSided = false`: cantos limpos.
        -   Detalhes que sobraram (vêm da pintura do Meshy): um brilho
            mínimo no canto externo do olho direito e uma pinta escura na
            lã do capuz. Só dá para corrigir repintando a textura.
-   Limitações restantes:
    -   A cauda está distribuída entre o quadril e as pernas pelo rig
        automático. Andando, o resultado está aceitável.
    -   O furo na palma da mão continua (fica para o polimento).
    -   `Precise` + `DoubleSided` custam mais desempenho. Medir quando
        houver vários personagens na tela.

## Câmera híbrida (Etapa 02, decisão do usuário)

-   Decisão: o jogo começa em terceira pessoa (para mostrar o disfarce) e
    o jogador pode dar zoom até a primeira pessoa.
    `StarterPlayer.CameraMinZoomDistance = 0.5` e `CameraMaxZoomDistance = 20`,
    configurados em `default.project.json`.
-   A mira da interação segue esta ordem:
    1.  O objeto no centro da tela (raio da câmera, alcance
        `InteractionConfig.LookRayLength` mais a distância da câmera),
        se estiver dentro do `MaxDistance`. A tag pode estar na peça ou
        num Model ancestral.
    2.  Se não houver, o objeto mais próximo dentro do alcance (como
        antes).
    -   O servidor não mudou: continua validando distância, estado e
        frequência.
-   Testado no playtest (câmera posicionada por script, personagem
    parado):
    -   Olhando para a placa → alvo "Sign".
    -   Olhando para o interruptor → "LightSwitch".
    -   Olhando para o céu ou para a porta fora do alcance → cai no mais
        próximo ("LightSwitch").
    -   Pedido ao servidor com o alvo mirado → `Ok`.
    -   Limites de zoom aplicados ao jogador (0,5 a 20). Sem erros no
        Output.
-   Fica para a Etapa 03: aproximar a câmera automaticamente ao carregar
    uma caixa.
-   Pendente/opcional: mostrar os braços e patas do lobo na primeira
    pessoa. Hoje o Roblox esconde o corpo inteiro nesse modo.
-   Teste manual: jogue, gire a roda do mouse até entrar em primeira
    pessoa e mire o interruptor, a placa e a porta. A dica deve seguir
    para onde você olha.

## Testes manuais pendentes

1.  **Aprovação do personagem v4:** jogue (F5) e avalie se a versão
    intermediária serve para continuar. Atenção às costas cinza e à
    cauda balançando com a perna.
2.  **Salvar:** o place agora está ligado à experiência publicada. Use
    Arquivo → Salvar na Roblox para a nuvem e **Arquivo → Salvar em
    arquivo** para atualizar o `lobo-project.rbxl` do Git, que é onde
    ficam o `StarterCharacter` e os modelos de origem.
3.  **Tecla E de verdade:** a tecla enviada pelo MCP não teve efeito
    confirmável, porque o usuário estava jogando ao mesmo tempo. Há
    indício de que o fluxo funcionou com o usuário: o aviso mostrou o
    texto da placa, que só aparece por interação. Confirme assim:
    1.  Chegue perto do interruptor amarelo e aperte E. A luz acende e
        aparece o aviso verde.
    2.  Aperte E na porta. Aparece o aviso vermelho "trancada".
    3.  Aperte E na placa. Aparece o texto da placa.
4.  **Handler da porta destrancada:** não foi confirmado. Para testar, no
    playtest mude o atributo `Enabled` da `StorageDoor` para true e
    aperte E. A porta fica translúcida e atravessável.
5.  **Gamepad e touch:** não testados. Use o emulador de dispositivo do
    Studio para ver o botão "Usar".

## Problemas conhecidos

-   Resolvido: os erros `Authentication required` e `MeshContentProvider
    ... could not fetch` vinham da sessão do Studio sem autenticação.
    Sumiram depois que o usuário refez o login.
-   `--!strict` está declarado, mas não existe verificador de tipos
    instalado. Erros de tipo só apareceriam no editor do Studio.
-   O place agora está publicado (privado). O `StarterCharacter` e os
    modelos gerados só existem no place: é preciso salvar em arquivo para
    que entrem no Git.
-   As Etapas 01 e 02 estão commitadas (`edf1d82` e `69c12f0`). A Etapa 03
    (com as animações, a caixa e o expositor definitivos) está na branch
    `feat/etapa-03-produtos-transporte`. O protótipo antigo continua no
    histórico, no commit `12815e8`.
-   Mudanças no mapa e nos modelos (`Workspace.Store`, `ServerStorage`,
    `StarterCharacter`) só entram no Git depois de Arquivo → Salvar em
    arquivo.
-   Existem duas cópias do repositório (`Desktop` e `Documents\GitHub`).

## Próxima ação autorizada

-   Aguardar a validação da Etapa 03 pelo usuário. Só então executar a
    Etapa 04 --- Clientes e vendas.
