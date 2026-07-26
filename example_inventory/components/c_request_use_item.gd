## One-shot request tag: "use this item". Added to the active item by
## [ItemsSystem]'s input subsystem when the use key is pressed; consumed (and
## removed via [code]cmd[/code]) by the request-use subsystem, which dispatches
## the item's [member C_Item.action].
##
## Request components decouple [i]asking[/i] from [i]doing[/i]: anything can add
## this tag (input, AI, a network message) and exactly one system honors it.
class_name C_RequestUseItem
extends Component
