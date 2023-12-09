public class Music.Lastfm : GLib.Object {
    private Soup.Session session;
    private Json.Parser parser;

    private string token;
    public string name;

    private static GLib.Once<Lastfm> _instance;
    public static unowned Lastfm get_default() {
        return _instance.once(() => { return new Lastfm(); });
    }

    construct {
        session = new Soup.Session();
        parser = new Json.Parser();
    }

    public async Json.Parser? request(string method, string? parameters) {
        string url = @"http://ws.audioscrobbler.com/2.0/?method=$method&api_key=$(Constants.LASTFM_API_KEY)&format=json$parameters";
        var message = new Soup.Message("GET", url);
        try {
            var res = yield session.send_async (message, GLib.Priority.DEFAULT, null);

            var data = new uint8[5000];
            size_t bytes_read;
            yield res.read_all_async(data, GLib.Priority.DEFAULT, null, out bytes_read);
            print ("Read %i bytes from %s\n%s\n", (int) bytes_read, url, (string) data);

            parser.load_from_data((string) data, (ssize_t) bytes_read);
            return parser;
        } catch (Error e) {
            warning (@"Couldn't send request to $method ($(e.message))\n");
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
        var plain_sig = @"api_key$(Constants.LASTFM_API_KEY)methodauth.getSessiontoken$token$(Constants.LASTFM_SHARED_SECRET)";
        print ("Signature is %s\n", plain_sig);
        var sig = GLib.Checksum.compute_for_string (MD5, plain_sig, plain_sig.length).to_string();
        yield request("auth.getSession", @"&token=$token&api_sig=$sig");
        var session = parser.get_root().get_object().get_object_member("session");
        if (session == null) {
            error ("Improper session");
        }
        var key = session.get_string_member("key");
        name = session.get_string_member("name");
        print ("key %s, name: %s\n", key, name);
        return key;
    }
}
