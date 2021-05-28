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
	[GtkTemplate (ui = "/io/github/chaotic-dev/manga/window.ui")]
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
		Hdy.Deck page_deck;
		[GtkChild]
		Hdy.Deck image_deck;
		[GtkChild]
		Gtk.Button next_btn;
		[GtkChild]
		Gtk.Button prev_btn;
		[GtkChild]
		Gtk.ListBox chapter_list;
		[GtkChild]
		Gtk.ListBox recent_manga_list;
		[GtkChild]
		Gtk.ScrolledWindow manga_chapters_page;
		[GtkChild]
		Gtk.Box chapter_read_page;
		[GtkChild]
		Gtk.ScrolledWindow reader_scrolled_window;

		private GLib.ListStore chapters_list_model;
		private GLib.ListStore mangas_list_model;
		private string current_chapter_id;
		private string current_manga_id;

		private string cache_dir;

		public Window (Gtk.Application app) {
			Object (application: app);
			string tmp_dir_path = GLib.Environment.get_tmp_dir ();
			cache_dir = GLib.Path.build_filename(tmp_dir_path, "io.github.chaotic-dev.manga");
			GLib.DirUtils.create (cache_dir, 0777);

			chapters_list_model = new GLib.ListStore (typeof (Mangadex.Chapter));
            chapter_list.bind_model (chapters_list_model, chapter_render_function);
            mangas_list_model = new GLib.ListStore (typeof (Mangadex.Manga));
            recent_manga_list.bind_model (mangas_list_model, manga_render_function);

            image_deck.get_swipe_tracker ().allow_mouse_drag = true;
			image_deck.can_swipe_forward = true;

            var mangas = Mangadex.Api.get_recent_mangas ();
            stdout.printf ("Manga count: %d\n", mangas.length);
            for (int i = 0; i < mangas.length; i++) {
                mangas_list_model.append ((GLib.Object) mangas[i]);
            }

		}

		private Gtk.Widget chapter_render_function (GLib.Object obj) {
		    var chapter = (Mangadex.Chapter) obj;
		    var ret = new Gtk.Label ("%s: %s".printf(chapter.chapter, chapter.title));
		    ret.show ();
		    return ret;
		}

		private Gtk.Widget manga_render_function (GLib.Object obj) {
            var manga = (Mangadex.Manga) obj;
            var ret = new Gtk.Label (manga.get_title());
            ret.show ();
            return ret;
		}

		private void show_manga (Mangadex.Manga manga) {
		    stderr.printf ("Showing manga %s...\n", manga.id);
            page_deck.set_visible_child (manga_chapters_page);
            if (manga.id == current_manga_id) {
                return;
            }
            current_manga_id = manga.id;
            chapters_list_model.remove_all ();
            var chapters = manga.get_chapters ();
            for (int i = 0; i < chapters.length; i++) {
                chapters_list_model.append ((GLib.Object)chapters[i]);
            }

		}

		private void show_chapter (Mangadex.Chapter chapter) {
		stderr.printf ("Showing chapter %s...\n", chapter.id);
		    page_deck.set_visible_child (chapter_read_page);
		    if (current_chapter_id == chapter.id) {
		        return;
		    }
		    current_chapter_id = chapter.id;
		    clear_deck (image_deck);
		    var chapter_links = chapter.get_pages_data_saver ();
		    var session = new Soup.Session ();
		    for (int i = 0; i < chapter_links.length; i++) {
		        var img = new Gtk.Image ();
		        img.show ();
		        image_deck.add (img);
			    var url = chapter_links[i];
                var fname = GLib.Path.get_basename (url);
                var fpath = GLib.Path.build_filename (cache_dir, fname);
                var file = GLib.File.new_for_path (fpath);
                if (file.query_exists ()) {
                    img.set_from_file (fpath);
                    // var buf = img.pixbuf;
                    // buf = buf.scale_simple (buf.width / 2, buf.height / 2, Gdk.InterpType.BILINEAR);
                    // img.pixbuf = buf;
                } else {
                    var file_stream = file.create (FileCreateFlags.NONE);
                    var req = session.request (url);
                    req.send_async.begin (null ,(obj, res) => {
                        try {
                            var stream = req.send_async.end (res);
                            file_stream.splice (stream, OutputStreamSpliceFlags.CLOSE_SOURCE);
	                        file_stream.close ();

	                        img.set_from_file (fpath);
	                        // var buf = img.pixbuf;
                         //    buf = buf.scale_simple (buf.width / 2, buf.height / 2, Gdk.InterpType.BILINEAR);
                         //    img .pixbuf = buf;
			                img.show ();
			                image_deck.add (img);
			            } catch (ThreadError e) {
			                string msg = e.message;
			                stderr.printf(@"Thread error: $msg\n");
			                file_stream.close ();
			            }
                    });
			    }
			}
			// TODO: Handle case where there are no pages or an error occurs
			image_deck.set_visible_child (image_deck.get_children ().data);
		}

		private void reset_scroll_window (Gtk.ScrolledWindow window) {
		    var hadj = window.hadjustment;
		    var vadj = window.vadjustment;

		    hadj.set_value (0);
		    window.hadjustment = hadj;

		    vadj.set_value (0);
		    window.vadjustment = vadj;
		}

        [GtkCallback]
		private void on_squeezer_visible_child_notify (ParamSpec pspec) {
		    var child = squeezer.get_visible_child ();
            bottom_switcher.set_reveal (child != headerbar_switcher);
		}

        [GtkCallback]
		private void on_chapter_list_row_activated (Gtk.ListBoxRow row) {
		    var index = row.get_index ();
		    show_chapter ((Mangadex.Chapter) chapters_list_model.get_item (index));
		}

		[GtkCallback]
		private void on_recent_manga_list_row_activated (Gtk.ListBoxRow row) {
		    var index = row.get_index ();
		    show_manga ((Mangadex.Manga) mangas_list_model.get_item (index));
		}

        [GtkCallback]
		private void on_next_btn_clicked () {
		    if (image_deck.visible_child != null) {
                image_deck.navigate (Hdy.NavigationDirection.FORWARD);
                reset_scroll_window (reader_scrolled_window);
            }
		}
        [GtkCallback]
		private void on_prev_btn_clicked () {
		    if (image_deck.visible_child != null) {
		        image_deck.navigate (Hdy.NavigationDirection.BACK);
		        reset_scroll_window (reader_scrolled_window);
		    }
		}

		[GtkCallback]
		private void on_back_btn_clicked () {
		    page_deck.navigate (Hdy.NavigationDirection.BACK);
		}

		private inline void clear_deck (Hdy.Deck deck) {
            deck.@foreach ((widget) => {
		        deck.remove (widget);
		    });
		}
	}
}
