# Wolf in Sheep's Clothing --- Plano de MVP

Este pacote organiza o desenvolvimento do jogo Roblox em etapas pequenas
e verificáveis para o Claude Code, usando VS Code, Roblox Studio, Rojo e
Luau.

## Como usar

1.  Extraia esta pasta dentro do repositório do jogo ou copie os
    documentos para a raiz do repositório.
2.  Leia `CLAUDE.md`. Ele contém as regras permanentes de trabalho.
3.  Leia `MVP.md` para entender o escopo mínimo e os critérios de
    sucesso.
4.  Execute **uma etapa por vez**, seguindo os arquivos em `etapas/`.
5.  Não peça para o Claude executar todas as etapas em uma única
    resposta. Ao terminar uma etapa, valide os critérios de aceite antes
    de avançar.
6.  Mantenha os documentos atualizados quando decisões técnicas ou o
    estado do projeto mudarem.

## Ordem de execução

-   `etapas/01_auditoria_e_base.md`
-   `etapas/02_personagem_e_interacao.md`
-   `etapas/03_produtos_e_fisica.md`
-   `etapas/04_clientes_e_vendas.md`
-   `etapas/05_disfarce_e_suspeita.md`
-   `etapas/06_multiplayer_e_validacao.md`
-   `etapas/07_interface_e_polimento.md`
-   `etapas/08_validacao_e_entrega.md`

## Regra de escopo

O MVP não é o jogo completo. Seu objetivo é provar que o núcleo é
divertido e tecnicamente confiável: movimentar-se, interagir,
transportar produtos, abastecer prateleiras, atender clientes, vender
mercadorias e gerar suspeita quando o jogador age de forma estranha.

Não adicione sistemas grandes fora do escopo antes de concluir e testar
esse ciclo.
