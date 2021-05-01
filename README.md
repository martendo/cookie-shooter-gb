# Cookie Shooter GB
A Game Boy arcade shooter game!

![Screenshot of gameplay](screenshots/cookie-shooter-gb.png)

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
There are 2 game modes: Classic and Super.

The game mode selection screen will appear after the title screen. From there, you can select the game mode you want to play.
High scores are kept separate for each game mode.

### Classic Mode
The original Cookie Shooter, plain and simple.

![Screenshot of gameplay in Classic mode](screenshots/classic-mode.png)

You shoot, hit cookies, and get points.
You get hit, you lose a life.
Lose all 3 lives, and the game is over.

### Super Mode
A fancy new way to play with power-ups!

![Screenshot of gameplay in Super mode](screenshots/super-mode.png)

All the fun of Classic Cookie Shooter, plus 5 power-ups, usable with the B button.

You can hold a maximum of 3 power-ups at a time, and out of those 3, you can select one to use with the up/down buttons.
When used, they override any currently in-use power-up, except for a couple of them which are "immediate": the Bomb and Extra Life immediately change things, and leave the current power-up in use.

Power-ups are given to you once your score passes a multiple of their point rates. The following table lists all power-ups in the game with their effects and their point rates.
<table>
  <thead>
    <tr>
      <th>Power-Up</th>
      <th>Point Rate</th>
      <th>Effect</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Fast Lasers</td>
      <td>4 000 points</td>
      <td>Speeds up all lasers for 15 seconds</td>
    </tr>
    <tr>
      <td>Bomb</td>
      <td>5 000 points</td>
      <td>Clears the screen of all cookies</td>
    </tr>
    <tr>
      <td>Slow Cookies</td>
      <td>7 000 points</td>
      <td>Slows down all cookies to half speed for 15 seconds</td>
    </tr>
    <tr>
      <td>Double Lasers</td>
      <td>9 000 points</td>
      <td>The spaceship will shoot 2 lasers at once for 20 seconds</td>
    </tr>
    <tr>
      <td>Extra Life</td>
      <td>10 000 points</td>
      <td>A life is added to your remaining lives</td>
    </tr>
  </tbody>
</table>

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

### Super Mode-Specific Controls
<table>
  <thead>
    <tr>
      <th>Button</th>
      <th>Function</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Up/Down</td>
      <td>Change power-up selection</td>
    </tr>
    <tr>
      <td>B</td>
      <td>Use power-up</td>
    </tr>
  </tbody>
</table>
