namespace Manga {
    [GtkTemplate (ui = "/io/github/chaotic-dev/manga/ui/chapter_listing.ui")]
    class ChapterListing : Gtk.Grid {
        [GtkChild]
        Gtk.Label number_label;
        [GtkChild]
        Gtk.Label title_label;
        [GtkChild]
        Gtk.Label group_label;

        public ChapterListing (Mangadex.Chapter chapter) {
            Object ();
            number_label.label = chapter.chapter;
            title_label.label = chapter.title;
            // TODO: Add lookup for group id
            group_label.label = chapter.group_id;
        }
    }
}
