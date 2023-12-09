public class Music.ConnectLastfm : Gtk.Popover {
    private Gtk.Window window;

    public ConnectLastfm(Gtk.Window window) {
        this.window = window;
    }

    construct {
        var box = new Gtk.Box (VERTICAL, 12) {
            margin_top = 24,
            margin_bottom = 24,
            margin_start = 24,
            margin_end = 24
        };

        var label = new Gtk.Label ("Click the below button to open a prompt to authenticate with last.fm.");
        box.append (label);

        var btn = new Gtk.Button.with_label ("Connect");
        btn.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        btn.clicked.connect (() => {
            popdown();
            Lastfm.get_default ().authenticate.begin (window);
        });
        box.append (btn);

        child = box;
    }
}
