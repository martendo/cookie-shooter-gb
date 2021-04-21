# Cookie Shooter GB
A Game Boy arcade shooter game!

Based on Cookie Shooter, one of the first games I've made.

## Building
Requirements:
- [RGBDS](https://github.com/gbdev/rgbds)
- [SuperFamiconv](https://github.com/Optiroc/SuperFamiconv)
- GNU Make

Run `make` in the root directory of the repository to produce `bin/cookie-shooter.gb`, along with its map and symbol files.

## How to Play
You're a spaceship flying through space with cookies coming at you!
Press the A button to shoot a laser and get points for blasting a cookie.
Try not to get hit by the cookies, though; you can only take 3 hits!

The smaller the cookie, the more points you get for hitting it &mdash; from 25 to 125 points.

As your score climbs, the game gets harder: more and more cookies will be on screen at once!

## Game Modes
**NOTE: The Super game mode is currently exactly the same as Classic! This game mode will be added soon.**

There are 2 game modes: Classic and Super.

A game mode selection screen will appear after the title screen where you can select the game mode you want to play.
High scores in each game mode are kept separate.

## In-Game Controls
<table>
  <thead>
    <tr>
      <th>Button</th>
      <th>Function</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Left/Right</td>
      <td>Move spaceship</td>
    </tr>
    <tr>
      <td>A</td>
      <td>Shoot laser</td>
    </tr>
    <tr>
      <td>START</td>
      <td>Pause/Resume game</td>
    </tr>
    <tr>
      <td>SELECT+START</td>
      <td>Quit game (only when paused)</td>
    </tr>
  </tbody>
</table>
