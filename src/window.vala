/* window.vala
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

namespace Manga {
	[GtkTemplate (ui = "/io/github/chaoticdev/manga/window.ui")]
	public class Window : Gtk.ApplicationWindow {
		[GtkChild]
		Hdy.HeaderBar header_bar;
		[GtkChild]
		Hdy.Squeezer squeezer;
		[GtkChild]
		Hdy.ViewSwitcher headerbar_switcher;
		[GtkChild]
		Hdy.ViewSwitcherBar bottom_switcher;
		[GtkChild]
		Hdy.Deck deck;

		private string cache_dir;

		public Window (Gtk.Application app) {
			Object (application: app);
			squeezer.notify["visible-child"].connect (on_squeezer_notify);
			string tmp_dir_path = GLib.Environment.get_tmp_dir ();
			cache_dir = GLib.Path.build_filename(tmp_dir_path, "io.github.chaoticdev.manga");
			GLib.DirUtils.create (cache_dir, 0777);

			var session = new Soup.Session ();
			var req = session.request ("https://api.mangadex.org/manga?order[updatedAt]=desc&limit=1");
			var parser = new Json.Parser ();
			var res = req.send ();
			parser.load_from_stream (res);
			res.close ();
			var root = parser.get_root ().get_object ();
			var results = root.get_array_member ("results");
			var result = results.get_object_element (0);
			var data = result.get_object_member ("data");
			string id = data.get_string_member ("id");

			req = session.request (@"https://api.mangadex.org/manga/$id/feed");
			res = req.send ();
			parser.load_from_stream (res);
			res.close ();
			root = parser.get_root ().get_object ();
			var chapters = root.get_array_member ("results");
			var chapter_obj = chapters.get_object_element (0);
			var chapter = new Mangadex.Chapter (chapter_obj);

			var chapter_links = chapter.get_pages_data_saver ();
			add_pages (chapter_links);

			deck.get_swipe_tracker ().allow_mouse_drag = true;

		}

		private void add_pages (string[] chapter_links) {
		    var session = new Soup.Session ();
		    for (int i = 0; i < chapter_links.length; i++) {
			    var url = chapter_links[i];
                var fname = GLib.Path.get_basename (url);
                var fpath = GLib.Path.build_filename (cache_dir, fname);
                var file = GLib.File.new_for_path (fpath);
                if (file.query_exists ()) {
                    var img = new Gtk.Image.from_file (fpath);
			        img.show ();
			        deck.add (img);
                } else {
                    var file_stream = file.create (FileCreateFlags.NONE);
                    var req = session.request (url);
                    req.send_async.begin (null ,(obj, res) => {
                        try {
                            var stream = req.send_async.end (res);
                            file_stream.splice (stream, OutputStreamSpliceFlags.CLOSE_SOURCE);
	                        file_stream.close ();

	                        var img = new Gtk.Image.from_file (fpath);
			                img.show ();
			                deck.add (img);
			            } catch (ThreadError e) {
			                string msg = e.message;
			                stderr.printf(@"Thread error: $msg\n");
			                file_stream.close ();
			            }
                    });
			    }
			}
		}

		private void on_squeezer_notify (ParamSpec pspec) {
		    var child = squeezer.get_visible_child ();
            bottom_switcher.set_reveal (child != headerbar_switcher);
		}
	}
}
