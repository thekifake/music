public class Music.Lastfm : GLib.Object {
    public bool authenticated = false;
    public Gee.TreeMap<string, string> song_pars;

    private Soup.Session session;
    private Json.Parser parser;
    private Settings settings;

    private string token;

    private static GLib.Once<Lastfm> _instance;
    public static unowned Lastfm get_default() {
        return _instance.once(() => { return new Lastfm(); });
    }

    construct {
        session = new Soup.Session();
        parser = new Json.Parser();
        settings = new Settings("io.elementary.music");
        if (settings.get_string ("lastfm-session-key") != "none" && settings.get_string ("lastfm-username") != "none") authenticated = true;
    }

    public async Json.Parser? request(string func, Gee.TreeMap<string, string>? parameters, string? method = "GET", bool? use_key = false) {
        print ("====== LAST.FM REQUEST ======\n");
        var pars = new Gee.TreeMap<string, string>(null, null);
        pars.set("api_key", Constants.LASTFM_API_KEY);
        pars.set("method", func);
        if (use_key) {
            var key = settings.get_string ("lastfm-session-key");
            if (key == "none") warning ("Key does not exist (yet)");
            pars.set("sk", key);
        }

        parameters.map_iterator().foreach((k, v) => {
            pars.set(k, v);
            return true;
        });

        string html_pars = "?";
        string plain_sig = "";
        pars.map_iterator().foreach((k, v) => {
            html_pars += @"$k=$(Uri.escape_string(v, null, true))&";
            plain_sig += @"$k$v";
            return true;
        });
        html_pars = html_pars.slice(0, -1);
        plain_sig += Constants.LASTFM_SHARED_SECRET;
        var sig = GLib.Checksum.compute_for_string (MD5, plain_sig, plain_sig.length).to_string();
        print ("Generated signature: %s\n", sig);

        string url = @"http://ws.audioscrobbler.com/2.0/$html_pars&format=json&api_sig=$sig";
        print("Generated URI: %s\n", url);

        var message = new Soup.Message(method, url);
        try {
            var res = yield session.send_async (message, GLib.Priority.DEFAULT, null);

            var data = new uint8[5000];
            size_t bytes_read;
            yield res.read_all_async(data, GLib.Priority.DEFAULT, null, out bytes_read);
            print ("Read %i bytes from %s\n%s\n", (int) bytes_read, url, (string) data);

            parser.load_from_data((string) data, (ssize_t) bytes_read);
            return parser;
        } catch (Error e) {
            warning (@"Couldn't send request to $func ($(e.message))\n");
            return null;
        }
    }

    public async string get_token() {
        yield request("auth.getToken", null);
        return parser.get_root().get_object().get_string_member("token");
    }

    // This appears to be broken
    public async void begin_authenticate(Gtk.Window parent) {
        token = yield get_token();
        print ("Got token %s\n", token);
        Gtk.show_uri(
            parent,
            @"http://www.last.fm/api/auth/?api_key=$(Constants.LASTFM_API_KEY)&token=$token",
            Gdk.CURRENT_TIME
        );
    }

    public async string end_authenticate() {
        var pars = new Gee.TreeMap<string, string>(null, null);
        pars.set("token", token);
        yield request("auth.getSession", pars);
        var session = parser.get_root().get_object().get_object_member("session");
        if (session == null) {
            error ("Improper session");
        }
        var key = session.get_string_member("key");
        var name = session.get_string_member("name");
        print ("key %s, name: %s\n", key, name);
        settings.set_string ("lastfm-session-key", key);
        settings.set_string ("lastfm-username", name);
        authenticated = true;
        return key;
    }

    public void set_song_pars() {
        var song = PlaybackManager.get_default().current_audio;
        if (song == null) {
            warning ("Song not found");
            return;
        }
        if (song.title == song_pars.get("track")) {
            print ("%s is already loaded", song_pars.get("track"));
            return;
        }
        song_pars = new Gee.TreeMap<string, string> (null, null);
        int duration = (int) (song.duration / 1000000000);
        print("Fields info:\n\ttitle:     %s\n\tartist:    %s\n\talbum:     %s\n\tduration:  %i seconds\n", song.title, song.artist, song.album, duration);
        if (song.title != null) {
            song_pars.set("track", song.title);
            song_pars.set("duration", duration.to_string());
            if (song.artist != null) song_pars.set("artist", song.artist);
            if (song.album != null) song_pars.set("album", song.album);
        }
    }

    public async void set_now_playing() {
        set_song_pars();
        yield request("track.updateNowPlaying", song_pars, "POST", true);
    }

    // TODO scrobble after scrobble-min-time
    public async void scrobble() {
        set_song_pars();
        song_pars.set("timestamp", Gdk.CURRENT_TIME.to_string());
        yield request("track.scrobble", song_pars, "POST", true);
    }
}
