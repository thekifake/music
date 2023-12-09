public class Music.Lastfm : GLib.Object {
    private Soup.Session session;
    private Json.Parser parser;

    private static GLib.Once<Lastfm> _instance;
    public static unowned Lastfm get_default() {
        return _instance.once(() => { return new Lastfm(); });
    }

    construct {
        session = new Soup.Session();
        parser = new Json.Parser();
    }

    public async void request(string method, string? parameters) {
        var message = new Soup.Message("GET", @"http://ws.audioscrobbler.com/2.0/?method=$method&api_key=$(Constants.LASTFM_API_KEY)&format=json$parameters");
        try {
            var res = yield session.send_async (message, GLib.Priority.DEFAULT, null);
            yield parser.load_from_stream_async(res, null);
        } catch (Error e) {
            warning (@"Couldn't send request to $method ($(e.message))\n");
        }
    }

    public async string get_token() {
        yield request("auth.getToken", null);
        return parser.get_root().get_object().get_string_member("token");
    }

    public async void authenticate(Gtk.Window parent) {
        var token = yield get_token();
        print (token);
        Gtk.show_uri(
            parent,
            @"http://www.last.fm/api/auth/?api_key=$(Constants.LASTFM_API_KEY)&token=$token",
            Gdk.CURRENT_TIME
        );
    }
}
