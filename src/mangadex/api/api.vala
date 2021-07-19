/* api.vala
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
namespace Mangadex.Api {
    Manga[] get_recent_mangas () {
        var session = new Soup.Session ();
		var req = session.request ("https://api.mangadex.org/manga?order[updatedAt]=desc");
		Manga[] ret = {};

		try {
		    var parser = new Json.Parser ();
		    var res = req.send ();
		    parser.load_from_stream (res);
		    res.close ();
		    var root = parser.get_root ().get_object ();
		    var results = root.get_array_member ("results");
		    for (int i = 0; i < results.get_length (); i++) {
                var result = results.get_object_element (i);
			    ret += new Mangadex.Manga (result);
		    }
		} catch (GLib.Error e) {
            stderr.printf ("Unable to parse results of recent manga query: %s\n", e.message);
		}

		return ret;
    }

    Manga[] get_featured_mangas () {
        var session = new Soup.Session ();
		var req = session.request ("https://api.mangadex.org/list/8018a70b-1492-4f91-a584-7451d7787f7a");
		Manga[] ret = {};

		try {
		    var parser = new Json.Parser ();
		    var res = req.send ();
		    parser.load_from_stream (res);
		    res.close ();
		    var root = parser.get_root ().get_object ();
		    var result = root.get_string_member ("result");
		    if (result != "ok") {
		        stderr.printf (@"Unable to fetch featured mangas: $result\n");
		        return ret;
		    }
		    var mangas = root.get_array_member ("relationships");

		    for (int i = 0; i < mangas.get_length (); i++) {
                var mref = mangas.get_object_element (i);
                if (mref.get_string_member ("type") == "manga") {
                    string id = mref.get_string_member ("id");
                    req = session.request (@"https://api.mangadex.org/manga/$id/");
                    res = req.send ();
                    parser.load_from_stream (res);
                    res.close ();
                    var manga_obj = parser.get_root ().get_object ();
                    stderr.printf ("Result: %s\n", manga_obj.get_string_member ("result"));
                    var manga = new Mangadex.Manga (manga_obj);
                    if (manga.is_valid) {
			            ret += manga;
			        }
			    }
		    }
		} catch (GLib.Error e) {
            stderr.printf ("Unable to parse results of featured manga list query: %s\n", e.message);
		}

		return ret;
    }

    string[] get_manga_covers (Manga[] mangas) {
        for (int i = 0; i < mangas.length; i++) {

        }
        return {};
    }

    string get_manga_cover (string cover_id) {
        stderr.printf (@"Cover id: $cover_id\n");
        var session = new Soup.Session ();
		var req = session.request (@"https://api.mangadex.org/cover?ids[]=$cover_id");

		try {
		    var parser = new Json.Parser ();
		    var res = req.send ();
		    parser.load_from_stream (res);
		    res.close ();
		    var root = parser.get_root ().get_object ();
		    var results = root.get_array_member ("results");
		    if (results.get_length () < 1) {
		        stderr.printf (@"Cover $cover_id not found...\n");
		        return "";
		    }
		    var result = results.get_object_element (0);
		    var data = result.get_object_member ("data");
		    var attribs = data.get_object_member ("attributes");
		    return attribs.get_string_member ("fileName");

		} catch (GLib.Error e) {
            stderr.printf ("Unable to parse results: %s\n", e.message);
            return "";
		}

    }
}
