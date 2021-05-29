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
            stderr.printf ("Unable to parse results: %s\n", e.message);
		}

		return ret;
    }
}
