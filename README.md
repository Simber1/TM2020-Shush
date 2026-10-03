# Shush

An [Openplanet](https://openplanet.dev/) plugin for Trackmania (2020) that mutes the engine sound of ghosts while you are driving.

## What it does

While you are actively driving (the player you control is the one on camera, UI in the "Playing" sequence, not force-spectating, 
not in an editor), every car engine source that does not belong to the car the camera follows is held at -100 dB, 
the level the game itself uses for muted sources.  
The plugin implements a game version check similar to Ghosts++/Editor++ to prevent outdated plugins from crashing newer
game versions.

## Development

The plugin is a plain folder plugin: symlink or copy this directory into `OpenplanetNext/Plugins/Shush` and enable Developer signature mode.
