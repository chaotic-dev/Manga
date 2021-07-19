namespace Manga {
    [GtkTemplate (ui = "/io/github/chaotic-dev/manga/ui/manga_listing.ui")]
    class MangaListing : Gtk.Grid {
        [GtkChild]
        Gtk.Image cover_image;
        [GtkChild]
        Gtk.Label title_label;
        [GtkChild]
        Gtk.Label description_label;

        public MangaListing (Mangadex.Manga manga) {
            Object ();
            title_label.label = manga.get_title ();
            string description = manga.get_description ();
            if (description.length > 100) {
                description = description.substring (0, 1000);
            }
            description_label.label = description;
            cover_image.set_from_file (manga.get_cover ());
        }
    }
}
