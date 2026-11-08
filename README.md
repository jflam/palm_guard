# palm_guard

Stops your palms from moving the cursor while you type on an Apple Silicon
MacBook running Linux (Asahi kernel). Tested on an M2 MacBook Pro (Mac14,6)
with [Omarchy](https://omarchy.org/) / Hyprland, but it works under any
compositor, because it acts at the kernel level.

## The problem

Palm rejection on Apple Silicon trackpads is weak under Linux. On macOS the
trackpad hardware does it, and that part of the chip hasn't been reverse
engineered yet. What Linux offers instead helps only a little:

- **libinput's disable-while-typing** only ignores touches that *start* while
  you're typing. A palm already resting on the pad keeps moving the cursor.
- **Turning tap-to-click off** stops accidental taps, but not cursor jumps.
- On **Hyprland**, focus follows the mouse by default, so a palm brush moves
  keyboard focus and your typing lands in another window.

People report the same thing in
[AsahiLinux/linux#280](https://github.com/AsahiLinux/linux/issues/280) and
[basecamp/omarchy#1273](https://github.com/basecamp/omarchy/discussions/1273).

## What palm-guard does

palm-guard is a small daemon (one Python file, standard library only) that
watches the **built-in** keyboard. After each keypress it switches the
built-in trackpad off through the kernel's `inhibited` switch in sysfs, and
switches it back on 0.5 s after your last key.

- Typing on an **external keyboard** never triggers it, so it stays out of the
  way when you're docked.
- **Modifier keys** (Ctrl, Shift, Alt, Cmd/Super, Fn) don't count, and pressing
  one switches the trackpad back on at once, so modifier-clicks still work.
- If the service stops or crashes, systemd switches the trackpad back on.

## Install

As an Arch package, built from the PKGBUILD in this repo (an AUR listing,
`palm-guard-git`, is coming once AUR registration reopens):

```bash
git clone https://github.com/jflam/palm_guard.git
cd palm_guard/aur
makepkg -si
sudo systemctl enable --now palm-guard
```

Or from a clone, without a package manager:

```bash
git clone https://github.com/jflam/palm_guard.git
cd palm_guard
./install.sh
```

`install.sh` puts `palm-guard` in `/usr/local/bin` and enables a systemd
service that starts at boot. palm-guard runs as root because it reads
`/dev/input` and writes to sysfs.

To check it's working, find the trackpad's event number with
`palm-guard --list` (on Apple Silicon it's usually `event0`), then run this
and type on the built-in keyboard. The value should flip to `1` while you type
and go back to `0` afterwards:

```bash
watch -n 0.1 cat /sys/class/input/event0/device/inhibited
```

Uninstall with `sudo pacman -R palm-guard-git`, or `./install.sh --uninstall` if you
installed from a clone.

## Configuration

Override these with `sudo systemctl edit palm-guard`, adding lines such as
`Environment=PALM_GUARD_HOLD=0.3` under `[Service]`, then
`sudo systemctl restart palm-guard`:

| Variable | Default | Meaning |
|---|---|---|
| `PALM_GUARD_HOLD` | `0.5` | Seconds to keep the trackpad off after the last key |
| `PALM_GUARD_KEYBOARD` | `Apple MTP keyboard` | Name of the built-in keyboard |
| `PALM_GUARD_TRACKPAD` | `Apple MTP multi-touch` | Name of the built-in trackpad |

The defaults match Apple Silicon MacBooks. On other laptops, find the names
with:

```bash
palm-guard --list
```

## Recommended Hyprland settings

These work well alongside palm-guard (in Omarchy, put them in
`~/.config/hypr/input.lua`):

```lua
hl.config({
  input = {
    -- Click to focus, like macOS: a stray palm can't move keyboard focus.
    follow_mouse = 2,
    touchpad = {
      tap_to_click = false,
      disable_while_typing = true,
    },
  },
})
```

## License

MIT
