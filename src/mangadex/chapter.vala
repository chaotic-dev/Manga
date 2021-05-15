namespace Mangadex {
    class Chapter : GLib.Object {
        public string id {get; private set;}
        public string volume {get; private set;}
        public string chapter {get; private set;}
        public string title {get; private set;}
        public string language {get; private set;}
        public string manga_id {get; private set;}
        public string group_id {get; private set;}
        public string user_id {get; private set;}
        public string published_at {get; private set;}
        public string created_at {get; private set;}
        public string updated_at {get; private set;}
        public string version {get; private set;}
        public bool is_valid {get; private set;}
        private string[] chapters = {};
        private string[] chapters_data_saver = {};
        private string hash;

        public Chapter (Json.Object obj)  {
            is_valid = true;
            if (!obj.has_member ("result") || obj.get_string_member ("result") != "ok") {
                // TODO: Use Logger
                stderr.puts ("Result malformed or not status 'ok'\n");
                is_valid = false;
                return;
            }
            var data = obj.get_object_member ("data");
            if (data.get_string_member ("type") != "chapter") {
                // TODO: Use Logger
                stderr.puts ("Result does not have type 'chapter'\n");
                is_valid = false;
                return;
            }
            id = data.get_string_member ("id");
            var attributes = data.get_object_member ("attributes");
            volume = attributes.get_string_member ("volume");
            chapter = attributes.get_string_member ("chapter");
            title = attributes.get_string_member ("title");
            language = attributes.get_string_member ("translatedLanguage");
            hash = attributes.get_string_member ("hash");
            published_at = attributes.get_string_member ("publishAt");
            created_at = attributes.get_string_member ("createdAt");
            updated_at = attributes.get_string_member ("updatedAt");
            version = attributes.get_string_member ("version");

            var chapter_array = attributes.get_array_member ("data");
            for (int i = 0; i < chapter_array.get_length (); i++) {
                chapters += chapter_array.get_string_element (i);
            }

            chapter_array = attributes.get_array_member ("dataSaver");
            for (int i = 0; i < chapter_array.get_length (); i++) {
                chapters_data_saver += chapter_array.get_string_element (i);
            }

            var relationships = obj.get_array_member ("relationships");
            for (int i = 0; i < relationships.get_length (); i++) {
                var o = relationships.get_object_element (i);
                // TODO: Add default in case of unexpected error
                switch (o.get_string_member ("type")) {
                    case "user":
                        user_id = o.get_string_member ("id");
                        break;
                    case "manga":
                        manga_id = o.get_string_member ("id");
                        break;
                    case "scanlation_group":
                        group_id = o.get_string_member ("id");
                        break;
                }
            }
        }

        private string get_server () {
            if (!is_valid) {
                return "";
            }
            var session = new Soup.Session ();
            var parser = new Json.Parser ();
            var req = session.request (@"https://api.mangadex.org/at-home/server/$id");
            var res = req.send ();
            parser.load_from_stream (res);
            res.close ();
            var root = parser.get_root ().get_object ();
            if (root.has_member ("baseUrl")) {
                return root.get_string_member ("baseUrl");
            }
            return "";
        }

        public string[] get_pages () {
            string[] pages = {};
            var server = get_server ();

            if (server == "") {
                return pages;
            }

            for (int i = 0; i < chapters.length; i++) {
                pages += "%s/data/%s/%s".printf (server, hash, chapters[i]);
            }
            return pages;
        }

        public string[] get_pages_data_saver () {
            string[] pages = {};
            var server = get_server ();

            if (server == "") {
                return pages;
            }

            for (int i = 0; i < chapters.length; i++) {
                pages += "%s/data-saver/%s/%s".printf (server, hash, chapters_data_saver[i]);
            }
            return pages;
        }
    }
}
