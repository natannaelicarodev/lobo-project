# Lanchonete do Lobo — regras do projeto

Jogo de Roblox: um lobo fantasiado de ovelha cuida de uma padaria numa vila de ovelhas
e precisa lucrar sem ser descoberto. Tycoon cômico + furtividade. Público 9 a 16 anos.

## Ferramentas
- Código em Luau, sincronizado com o Studio pelo Rojo (default.project.json).
- src/server → ServerScriptService | src/client → StarterPlayerScripts | src/shared → ReplicatedStorage
- Use o MCP Roblox_Studio para inspecionar o jogo, criar peças no Workspace,
  rodar playtests e ler o Output. Scripts sempre como arquivos em src/, nunca direto no Studio.

## Regras de código
- Toda regra de jogo roda no servidor. O cliente só mostra interface e envia intenções.
- O servidor sempre revalida RemoteEvents (distância, estado, quem enviou).
- Um ModuleScript por sistema: DayManager, CustomerSpawner, OrderService,
  SuspicionService, VanishService, SheriffService, DataService.
- Valores de balanceamento em src/shared/Config.luau, nunca espalhados no código.
- Nomes de código em inglês; textos que o jogador vê em português.
- Depois de cada mudança, rode um playtest pelo MCP e confira se o Output não tem erros.

## Regras de conteúdo (Roblox)
- Nada de sangue, mordida ou violência. O "sumiço" do cliente é um "puf" com fumaça
  e confete, e ele vira uma caixa de presente.
- Ingredientes do porão são "lã mágica", nunca carne.

## Forma de trabalhar
- Construir em fatias pequenas e jogáveis. Explicar em português simples o que mudou.
- Usar peças simples como placeholder até a arte ficar pronta.