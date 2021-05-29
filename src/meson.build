manga_sources = [
  'main.vala',
  'window.vala',
  'manga_listing.vala',
  'mangadex/chapter.vala',
  'mangadex/manga.vala',
  'mangadex/api/api.vala'
]

manga_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  dependency('libhandy-1', version: '>= 1.0.0'),
  dependency('libsoup-2.4', version: '>= 2.66.0'),
  dependency('json-glib-1.0', version: '>= 1.0.0')
]

gnome = import('gnome')

manga_sources += gnome.compile_resources('manga-resources',
  'manga.gresource.xml',
  c_name: 'manga'
)

executable('manga', manga_sources,
  vala_args: '--target-glib=2.50',  dependencies: manga_deps,
  install: true,
)
