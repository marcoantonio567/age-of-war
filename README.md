# Age of War - Godot

Recriacao em Godot do classico jogo Flash Age of War.

O projeto usa artes e sons extraidos do jogo original. A musica principal e
Glorious Morning, de Waterflame: https://www.youtube.com/watch?v=7T_YtklLyyo

Versao jogavel original do projeto: https://awesomea.itch.io/age-of-war

## Sobre o jogo

Age of War e um jogo 2D de estrategia em tempo real. O jogador treina unidades,
defende sua base, ganha dinheiro e experiencia ao derrotar inimigos, evolui por
eras e tenta destruir a base adversaria.

Este fork adiciona um controlador de IA para jogar no lugar do jogador humano,
ferramentas de visualizacao das decisoes e melhorias para suportar simulacao em
velocidade acelerada.

## Principais alteracoes feitas

### IA jogando pelo jogador

- Adicionado `player_ai_controller.gd`.
- A IA observa dinheiro, XP, vida das bases, pressao inimiga e forca relativa dos exercitos.
- A IA decide automaticamente quando:
  - treinar unidades melee, range, tank e super soldier;
  - evoluir para a proxima era;
  - usar especial;
  - comprar slots de torre;
  - comprar e melhorar torres.
- A IA e ativada automaticamente na cena `main_game.tscn`.

### Visualizador de rede neural

- Adicionado `UI/ai_decision_visualizer.gd`.
- O HUD mostra uma rede visual em tempo real com:
  - entradas: `pressure`, `money`, `xp`, `army`, `base`;
  - saidas: `advance`, `special`, `turret`, `tank`, `range`, `melee`;
  - decisao atual da IA.
- O visualizador ajuda a acompanhar por que a IA escolheu uma acao.

### Sistema de treino evolutivo temporario

- A IA registra temporariamente suas decisoes em `GlobalVariables.ai_decision_log`.
- Cada tentativa guarda:
  - geracao;
  - decisao tomada;
  - progresso do jogo;
  - era atual;
  - dinheiro;
  - XP;
  - entradas e saidas da rede;
  - pesos atuais da estrategia.
- Quando a IA perde no modo impossivel, o jogo reinicia automaticamente.
- A IA compara a tentativa atual com a melhor tentativa anterior.
- A estrategia e mutada a partir dos melhores pesos encontrados ate entao.
- O objetivo e permitir que a IA aprenda por tentativa e erro quais decisoes levam mais longe.

### Barra de progresso da IA

- Adicionada uma barra no HUD para acompanhar a tentativa atual.
- A pontuacao de progresso considera:
  - era alcancada;
  - dano causado na base inimiga;
  - vida restante da base do jogador;
  - tempo de sobrevivencia.
- O HUD mostra a geracao atual, o progresso atual e o melhor progresso ja obtido.

### Controle de velocidade

- Adicionado botao no HUD para alternar velocidade:
  - `1x`
  - `2x`
  - `4x`
- A velocidade usa `Engine.time_scale`.
- A velocidade selecionada fica salva temporariamente em `GlobalVariables.game_speed`.

### Correcao de dano em velocidades altas

Antes, muitos ataques dependiam de um frame exato da animacao:

```gdscript
if animated_sprite.frame == 19:
	do_damage(...)
```

Em `2x` ou `4x`, a animacao podia pular esse frame e o dano nao acontecia.

Foi adicionada a funcao `consume_animation_frame_event(...)` em:

- `scripts/melee_unit.gd`
- `range_unit.gd`
- `bases/turret.gd`

Agora o jogo detecta se a animacao passou pelo frame de ataque, mesmo quando
frames sao pulados. Isso corrige unidades e torres que deixavam de causar dano
em velocidade acelerada.

## Arquivos importantes

- `main_game.tscn`: cena principal do jogo.
- `main_game.gd`: logica principal da partida.
- `player_ai_controller.gd`: controlador da IA do jogador.
- `UI/ai_decision_visualizer.gd`: visualizacao da rede de decisoes.
- `UI/in_game_menu.gd`: HUD, fila de unidades, botao de velocidade e barra de progresso.
- `globals/global_variables.gd`: estado global, treino temporario e memoria da IA.
- `bases/player_base.gd`: vida das bases, vitoria/derrota e helpers de torre para IA.
- `bases/turret.gd`: logica de torres e correcao de eventos por frame.
- `scripts/melee_unit.gd`: classe base para unidades melee.
- `range_unit.gd`: classe base para unidades de alcance.

## Como rodar

1. Abra o projeto no Godot 4.
2. Rode a cena principal pelo menu.
3. Escolha a dificuldade.
4. Para observar o treino automatico da IA, escolha o modo impossivel.
5. Use o botao `1x/2x/4x` no HUD para acelerar ou desacelerar a simulacao.

## Observacoes

- A memoria da IA e temporaria e fica no autoload `GlobalVariables` durante a execucao.
- Ao fechar o jogo, o treino atual nao e salvo em arquivo.
- O sistema implementado e uma IA heuristica/evolutiva leve, nao uma rede neural treinada offline.
- O painel visual representa os sinais e pesos de decisao da IA em tempo real.
