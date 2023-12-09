# Music
[![Translation status](https://l10n.elementary.io/widgets/music/-/svg-badge.svg)](https://l10n.elementary.io/projects/music/?utm_source=widget)

![Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* granite-7
* gstreamer-1.0
* gstreamer-pbutils-1.0
* gstreamer-tag-1.0
* gtk4
* meson
* valac

You'll need to [create your own Last.fm API account](https://www.last.fm/api/account/create) and add the API key and shared secret to .env:

```
LASTFM_API_KEY=[ KEY ]
LASTFM_SHARED_SECRET=[ SECRET ]
```

It's recommended to create a clean build environment. Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.music`

    ninja install
    io.elementary.music
