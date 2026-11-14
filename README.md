<div align="center">

![Version](https://img.shields.io/github/v/release/RedSMURF16/Cage?label=version&color=blue) ![Total Downloads](https://img.shields.io/github/downloads/RedSMURF16/Cage/total?color=green)

</div>

<h1 align="center">Cage</h1>

## Description
This plugin adds placeable Cages to Counter-Strike 1.6, allowing players to trap themselves or other players behind iron bars.
- Place and configure Cages around the map
- Cage and release players with opening and closing sequences
- Execute players after a configurable holding duration
- Customize cage and forced cage messages
- Configure affected teams and usage restrictions by team
- Customize holding durations and screen shake effects
- Play configurable cage, opening and closing sounds
- Display customizable HUD effects during executions
- Configure whether sounds and messages are displayed on death
- Configure whether weapons are stripped when players are caged
- Choose whether already caged players are released
- Allow players to vote to cage other players
- Configure vote cooldown, duration and required percentage
- Save and load Cage placements per map
- Configure default behavior and create custom Cage presets

## Requirements
- ReGameDLL
- AMX Mod X 1.10+

## Configuration
```ini
# To add a new Cage, follow the example below:
# [Cage Name]
# CAGE_TEAM       = 0 - None, 1 - Terrorist, 2 - Counter-Terrorist, 3 - Both
#
# Define a section name to make a Cage available in the menu.
# Models and sounds cannot be changed dynamically during gameplay.
```

## Changelog
```text
* v1.0: Initial release.
```

[![Watch on YouTube](https://img.shields.io/badge/YouTube-Watch%20Preview-red?logo=youtube)](https://www.youtube.com/watch?v=LacunMfMo48)
