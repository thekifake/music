public class Music.ConnectLastfm : Gtk.Popover {
    private MainWindow window;
    private Settings settings;
    private Gtk.Stack stack;

    public ConnectLastfm(MainWindow window) {
        this.window = window;
    }

    construct {
        settings = new Settings ("io.elementary.music");

        var lf = Lastfm.get_default ();
        stack = new Gtk.Stack() {
            transition_type = OVER_LEFT_RIGHT,
            transition_duration = 400,
            margin_top = 24,
            margin_bottom = 24,
            margin_start = 24,
            margin_end = 24
        };

        var unauth_box = new Gtk.Box (VERTICAL, 12);
        var connect_label = new Gtk.Label (_("Click Authenticate to open a prompt to authenticate with last.fm."));
        unauth_box.append (connect_label);

        var connect_button = new Gtk.Button.with_label (_("Authenticate"));
        connect_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);


        var finalize_button = new Gtk.Button.with_label (_("Connect"));

        connect_button.clicked.connect (() => {
            popdown();
            connect_button.sensitive = false;
            lf.begin_authenticate.begin (window, () => {
                connect_button.sensitive = true;
                finalize_button.sensitive = true;
            });
        });
        unauth_box.append (connect_button);

        var finalize_label = new Gtk.Label (_("After you've granted Music access to your account, click Connect."));
        unauth_box.append (finalize_label);
        unauth_box.append (finalize_button);
        stack.add_named (unauth_box, "unauth");

        var temp_auth_box = new Gtk.Box (VERTICAL, 12);
        {
            var label = new Gtk.Label("Loading user information...");
            temp_auth_box.append(label);
            var dc_button = new Gtk.Button.with_label("Disconnect");
            temp_auth_box.append(dc_button);
        }
        stack.add_named (temp_auth_box, "auth");

        finalize_button.clicked.connect (() => {
            connect_button.sensitive = false;
            finalize_button.sensitive = false;
            lf.end_authenticate.begin ((obj, res) => {
                var key = lf.end_authenticate.end (res);
                replace_auth_box(temp_auth_box);
                stack.set_visible_child_name ("auth");
            });
        });

        if (!lf.authenticated) {
            stack.set_visible_child_name ("unauth");
        } else {
            stack.set_visible_child_name ("auth");
            replace_auth_box(temp_auth_box);
        }
        child = stack;
    }

    private void replace_auth_box(Gtk.Widget replacement) { // meh.....
        render_auth_box.begin((obj, res) => {
            var auth_box = render_auth_box.end(res);
            stack.remove(replacement);
            stack.add_named (auth_box, "auth");
        });
    }

    public async Gdk.Pixbuf? get_image(string url) {
        var session = new Soup.Session();
        var msg = new Soup.Message("GET", url);
        try {
            var res = yield session.send_async(msg, Priority.LOW, null);
            return yield new Gdk.Pixbuf.from_stream_async(res, null);
        } catch (Error e) {
            warning ("Couldn't get image from server (%s)", e.message);
            return null;
        }
    }

    public async Gtk.Box render_auth_box() {
        var lf = Lastfm.get_default();
        var box = new Gtk.Box (VERTICAL, 12) {
            valign = CENTER,
            halign = CENTER
        };

        var pars = new Gee.TreeMap<string, string>(null, null);
        pars.set("user", settings.get_string("lastfm-username"));
        var userinfo = (yield lf.request("user.getInfo", pars))
                       .get_root().get_object().get_object_member("user");

        var avatar_url = userinfo.get_array_member("image").get_element(2).get_object().get_string_member("#text");
        print ("URL: %s\n", avatar_url);
        var avatar_image = new Gtk.Image.from_pixbuf(yield get_image(avatar_url));
        avatar_image.set_pixel_size(125);
        box.append(avatar_image);

        var header_label = new Gtk.Label(userinfo.get_string_member("name"));
        header_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);
        box.append(header_label);

        var unjoined_date = userinfo.get_object_member("registered").get_string_member("unixtime");
        var joined_date = new DateTime.from_unix_utc(int64.parse(unjoined_date, 10)).format("%B %d, %Y");
        var plays_label = new Gtk.Label(@"$(userinfo.get_string_member("playcount")) scrobbles | Joined $joined_date");
        plays_label.add_css_class(Granite.STYLE_CLASS_H4_LABEL);
        box.append(plays_label);

        // TODO
        var dc_button = new Gtk.Button.with_label("Disconnect");
        box.append(dc_button);

        return box;
    }
}

