## Player entity — pure logic, no visuals of its own. Carries C_Player
## (identity) and C_Health (card count rendered as a fighting-game health
## bar by S_HealthBars; kept in sync by O_Ui as cards change spots).
##
## Authored as `e_player.tscn`. Each instance in `main.tscn` configures its
## own component sub-resources (id / display_name) in the inspector.
##
## Named CardPlayer to avoid colliding with the example_network/Player class.
@tool
class_name CardPlayer
extends Entity
