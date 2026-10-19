# Telegram Desktop Guix Channel

A Guix channel providing latest Telegram Desktop package with updated dependencies and enhanced functionality.

## Usage

Add this channel to your `~/.config/guix/channels.scm`:

```scheme
(cons* (channel
        (name 'telegram-desktop)
        (branch "main")
        ;; or
        (commit "v7.3.1")
        (url "https://github.com/johnlepikhin/guix-telegram-desktop"))
       %default-channels)
```

Then install with: `guix install telegram-desktop`

## Building a checkout

Telegram 7.3.1 uses the `tdesktop-rust` package from the `x-files` channel for its animation and wallet libraries. Its Cargo dependencies are source inputs generated from the pinned upstream lockfiles with Guix's `cargo-inputs-from-lockfile`; individual crate package definitions are unnecessary.

Use a Guix revision providing `cargo-inputs-from-lockfile` and `rust-1.95`. The `x-files` dependency bootstraps Rust 1.96.1, which the wallet engine requires.

The Rust package runs the wallet unit tests and runs animation tests serially to avoid timing failures on busy builders. Five `tlottie` tests are excluded because they still assume the older rendering limits, before [upstream commit `8386793f8857`](https://github.com/dkaraush/tlottie/commit/8386793f8857a5cf81372ba957477481d7c6cbe6) increased them; the exclusions are listed in `(x-files packages telegram-rust)`.

With an `x-files` checkout beside this repository, build the pinned package with:

```sh
guix build -L . -L ../x-files/src \
  -e '(@ (telegram-desktop packages telegram-desktop) telegram-desktop)' \
  -K -c 8 --max-jobs=1
```

To build on `base.home`, prefix that command with `GUIX_DAEMON_SOCKET=ssh://shegeley@10.0.0.3`. The resulting store path belongs to the remote machine; retrieve it with `guix copy --from=shegeley@10.0.0.3 STORE-PATH`.

The package removes Make's additional load-average limit so builds on busy hosts still use the requested `--cores` setting. Choose that setting according to the builder's available memory.
