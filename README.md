# Cookie Shooter GB
A Game Boy demake of one of my first games, Cookie Shooter!

## How to Play
You're a spaceship flying through space with cookies coming at you!
Press the A button to shoot a missile and get points for blasting a cookie.
Try not to get hit by the cookies, though; you can only take 3 hits!

### Controls
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
      <td>Shoot Missile</td>
    </tr>
  </tbody>
</table>

## Building
Requirements:
- [RGBDS](https://github.com/gbdev/rgbds)
- [SuperFamiconv](https://github.com/Optiroc/SuperFamiconv)
- GNU Make

Run `make` in the root directory of the repository to produce `bin/cookie-shooter.gb`, along with its map and symbol files.
