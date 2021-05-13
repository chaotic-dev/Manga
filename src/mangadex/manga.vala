namespace Mangadex {
    class Manga {
        string id {get; private set;}
        string title {get; private set;}
        string[] alt_titles {get; private set;}
        string description {get; private set;}

        public Manga (Json.Object obj) {

        }
    }
}
