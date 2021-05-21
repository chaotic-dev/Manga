/* manga.vala
 *
 * Copyright 2021 ChaoticDev
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
namespace Mangadex {

    class Manga : GLib.Object {
        private GLib.HashTable<string, string> title_lookup;
        private GLib.HashTable<string, string> description_lookup;
        private GLib.HashTable<string, GLib.Array<string>> alt_title_lookup;

        public string id {get; private set;}
        public string author_id {get; private set;}
        public string artist_id {get; private set;}
        //(string, string)[] links {get; private set;}
        public string original_language {get; private set;}
        public string last_volume {get; private set;}
        public string last_chapter {get; private set;}
        public string demographic {get; private set;}
        public string status {get; private set;}
        public string content_rating {get; private set;}
        public bool is_valid {get; private set;}

        public Manga (Json.Object obj) {
            is_valid = true;
            if (!obj.has_member ("result") || obj.get_string_member ("result") != "ok") {
                // TODO: Use Logger
                stderr.puts ("Result malformed or not status 'ok'\n");
                is_valid = false;
                return;
            }
            var data = obj.get_object_member ("data");
            if (data.get_string_member ("type") != "manga") {
                // TODO: Use Logger
                stderr.puts ("Result does not have type 'manga'\n");
                is_valid = false;
                return;
            }
            id = data.get_string_member ("id");
            var attributes = data.get_object_member ("attributes");

            // Handle manga titles for each language
            title_lookup = new GLib.HashTable<string, string> (str_hash, str_equal);
            var title_obj = attributes.get_object_member ("title");
            var members = title_obj.get_members ();
            for (int i = 0; i < members.length(); i++) {
                var lang = members.nth_data (i);
                title_lookup.insert (lang, title_obj.get_string_member (lang));
            }

            // Handle alternate titles for each language
            alt_title_lookup = new GLib.HashTable<string, GLib.Array<string>> (str_hash, direct_equal);
            var titles = attributes.get_array_member ("altTitles");
            for (int i = 0; i < titles.get_length (); i++) {
                var alt_title_obj = titles.get_object_element (i);
                members = title_obj.get_members ();
                for (int j = 0; j < members.length(); j++) {
                    var lang = members.nth_data (j);
                    if (alt_title_lookup[lang] == null) {
                        alt_title_lookup[lang] = new GLib.Array<string> ();
                    }
                    alt_title_lookup[lang].append_val (alt_title_obj.get_string_member (lang));
                }
            }

            // Handle description for each language
            description_lookup = new GLib.HashTable<string, string> (str_hash, str_equal);
            var desc_obj = attributes.get_object_member ("description");
            members = desc_obj.get_members ();
            for (int i = 0; i < members.length(); i++) {
                var lang = members.nth_data (i);
                description_lookup.insert (lang, desc_obj.get_string_member (lang));
            }

            original_language = attributes.get_string_member ("originalLanguage");
            last_volume = attributes.get_string_member ("lastVolume");
            last_chapter = attributes.get_string_member ("lastChapter");
            demographic = attributes.get_string_member ("publicationDemographic");
            status = attributes.get_string_member ("status");
            content_rating = attributes.get_string_member ("contentRating");

        }

        public string get_title (string lang = "en") {
            if (!is_valid) {
                return "";
            }
            var title = title_lookup[lang];
            return title == null ? "" : title;
        }

        public string[] get_alt_titles (string lang = "en") {
            if (!is_valid) {
                return {};
            }
            var titles = alt_title_lookup[lang].data;
            return titles;
        }

        public string get_description (string lang = "en") {
            if (!is_valid) {
                return "";
            }
            var desc = description_lookup[lang];
            return desc == null ? "" : desc;
        }

        public Chapter[] get_chapters (string lang = "en") {
            if (!is_valid) {
                return {};
            }
            var session = new Soup.Session ();
            var parser = new Json.Parser ();
            Chapter[] ret = {};
            uint offset = 0;
            uint total_results = 0;
            uint limit = 0;

            do {
                var req = session.request (@"https://api.mangadex.org/manga/$id/feed?locales[0]=$lang&order[volume]=desc&order[chapter]=desc&offset=$offset");
			    var res = req.send ();
			    parser.load_from_stream (res);
			    res.close ();


                stdout.printf (@"Getting chapters page $offset\n");

			    var root = parser.get_root ().get_object ();
			    total_results = (uint) root.get_int_member ("total");
			    limit = (uint) root.get_int_member ("limit");
			    offset += limit;
			    var chapters = root.get_array_member ("results");

                for (int i = 0; i < chapters.get_length(); i++) {
                    var chapter_obj = chapters.get_object_element (i);
			        ret += new Chapter (chapter_obj);
			    }
			} while (offset <= total_results);
			return ret;
        }
    }
}
