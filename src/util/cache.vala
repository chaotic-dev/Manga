
namespace Util.Cache {

    static string cache_dir;

    string initialize () {
        string tmp_dir_path = GLib.Environment.get_tmp_dir ();
	    cache_dir = GLib.Path.build_filename(tmp_dir_path, "io.github.chaoticdev.manga");
	    GLib.DirUtils.create (cache_dir, 0755);
	    return cache_dir;
    }

    string create_path (string subdir1, ...) {
        var list = va_list();
        string subdir = GLib.Path.build_filename_valist (subdir1, list);
        string path = GLib.Path.build_filename (cache_dir, subdir);
        int status = GLib.DirUtils.create_with_parents (path, 0755);
        if (status != 0) {
            stderr.printf (@"An error occurred creating directory: $path\n");
        }
        return path;
    }

}
