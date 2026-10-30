# Status de desenvolvimento

> Claude: atualize este documento ao concluir cada etapa. Registre
> somente o que foi realmente implementado e verificado.

## Etapa atual

-   Número: 02 --- Personagem e interação
-   Estado: Concluída (aguardando validação do usuário para iniciar a Etapa 03)

## Histórico

-   Etapa 01 --- Auditoria e base: concluída. O protótipo antigo da
    padaria foi removido a pedido do usuário.
-   Etapa 02 --- Personagem e interação: concluída (detalhes abaixo).

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
-   A limpeza do protótipo antigo e a Etapa 02 ainda não foram
    commitadas. O protótipo antigo continua no commit `12815e8`.
-   Existem duas cópias do repositório (`Desktop` e `Documents\GitHub`).

## Próxima ação autorizada

-   Aguardar a aprovação do personagem intermediário (v4) e a validação
    da Etapa 02 pelo usuário. Só então executar a Etapa 03 --- Produtos,
    transporte e física.
