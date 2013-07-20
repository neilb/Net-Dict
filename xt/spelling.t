use Test::More;

BEGIN {
    plan skip_all => "Spelling tests only for authors"
        unless -d 'inc/.author';
}

use Test::Spelling;
all_pod_files_spelling_ok();
