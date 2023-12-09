sources = [
    'Application.vala',
    'AudioObject.vala',
    'Lastfm.vala',
    'MainWindow.vala',
    'PlaybackManager.vala',
    'DBus/MprisPlayer.vala',
    'DBus/MprisRoot.vala',
    'Views/NowPlayingView.vala',
    'Widgets/AlbumImage.vala',
    'Widgets/ConnectLastfm.vala',
    'Widgets/SeekBar.vala',
    'Widgets/TrackRow.vala',
]

executable(
    meson.project_name(),
    gresource,
    sources,
    config_file,
    dependencies: dependencies,
    install: true
)
