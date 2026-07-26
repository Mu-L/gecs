## Tag on doors that block passage. [UseKeyAction] removes it; [O_Door] reacts to
## the removal ([code]on_removed[/code]) by opening the door visually and
## disabling its collision. The action never touches nodes and the observer never
## touches game rules: the component removal is the entire contract between them.
class_name C_Locked
extends Component
