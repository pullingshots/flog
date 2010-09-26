package pullingshots;
use Dancer ':syntax';
use Dancer::Plugin::Database;

our $VERSION = '0.1';

sub posts {
  use File::Fu;
  use DateTime;
  use Text::Markdown 'markdown';
  use URI::Encode qw(uri_encode uri_decode);

  my $dir = File::Fu->dir(config->{appdir} . '/public/posts/');
  my @files;

  my $fn = shift;
  if ($fn) {
    $fn = uri_decode($fn);
    @files = $dir->find(sub{ /\/\Q$fn\E$/ });
  }
  else {
    @files = $dir->list;
  }

  my @posts = map { 
    { 
      updated => DateTime->from_epoch( epoch => $_->stat->mtime ),
      title   => $_->basename, 
      content => join("", $_->read),
      who     => getpwuid($_->stat->uid), 
    } if $_->is_file 
  } @files;

  foreach (@posts) { 
    $_->{slug} = uri_encode($_->{title}, true);
    $_->{html} = markdown($_->{content});
  }

  @posts
}

get '/' => sub {

  my @posts = posts;

  template 'index', { posts => \@posts };
};

get qr{/(rdf|rss|atom).*} => sub {
  use XML::Atom::SimpleFeed;
  use File::Fu;
  use DateTime::Format::Atom;

  my @posts = posts;
  my $fa = DateTime::Format::Atom->new();
  my $dir = File::Fu->dir(config->{appdir} . '/public/posts/');

  my $updated = DateTime->from_epoch( epoch => $dir->stat->mtime );
  my $feed = XML::Atom::SimpleFeed->new(
     title   => 'pullingshots',
     link    => 'http://pullingshots.ca/',
     link    => { rel => 'self', href => 'http://pullingshots.ca/atom', },
     updated => $fa->format_datetime($updated),
     author  => 'Andrew Baerg',
     id      => 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6',
  );

  foreach (@posts) {
    $feed->add_entry(
     title     => $_->{title},
     link      => uri_for($_->{slug}),
     id        => 'urn:uuid:' . $_->{slug},
     summary   => $_->{html},
     updated   => $fa->format_datetime($_->{updated}),
     category  => 'Miscellaneous',
    );
  }
 
  content_type 'application/xhtml+xml';

 $feed->as_string;
};

get '/:post' => sub {

  my @posts = posts(params->{post});

  if (! scalar @posts) {
    status 'not_found';
    return "Nothing to see here.";
  }

  template 'index', { posts => \@posts };
};

true;
