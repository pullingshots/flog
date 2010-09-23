package pullingshots;
use Dancer ':syntax';
use Dancer::Plugin::Database;

our $VERSION = '0.1';

get '/' => sub {
  use File::Fu;
  use DateTime;

  my $dir = File::Fu->dir(config->{appdir} . '/public/posts/');
  my @posts = map { 
    { 
      updated => DateTime->from_epoch( epoch => $_->stat->mtime ),
      title   => $_->basename, 
      content => join("", $_->read),
      who     => getpwuid($_->stat->uid), 
    } if $_->is_file 
  } $dir->list;

  foreach (@posts) { 
	$_->{content} =~ s/\n\n/<\/p><p>/g;
	$_->{content} = "<p>" . $_->{content} . "</p>"; 
    $_->{slug} = $_->{title};
    $_->{slug} =~ s/\s/_/g;
  } 

  template 'index', { posts => \@posts };
};

get qr{/(rdf|rss|atom).*} => sub {
  use XML::Atom::SimpleFeed;
  use File::Fu;
  use DateTime;
  use DateTime::Format::Atom;

  my $fa = DateTime::Format::Atom->new();

  my $dir = File::Fu->dir(config->{appdir} . '/public/posts/');
  my @posts = map { 
    { 
      updated => DateTime->from_epoch( epoch => $_->stat->mtime ),
      title   => $_->basename, 
      content => join("", $_->read),
      who     => getpwuid($_->stat->uid), 
    } if $_->is_file 
  } $dir->list;

  foreach (@posts) { 
	$_->{content} =~ s/\n\n/<\/p><p>/g;
	$_->{content} = "<p>" . $_->{content} . "</p>";
  }
 
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
    my $slug = $_->{title};
    $slug =~ s/\s/_/g;
    $feed->add_entry(
     title     => $_->{title},
     link      => 'http://pullingshots.ca/' . $slug,
     id        => 'urn:uuid:' . $slug,
     summary   => $_->{content},
     updated   => $fa->format_datetime($_->{updated}),
     category  => 'Miscellaneous',
    );
  }
 
  content_type 'application/xhtml+xml';

 $feed->as_string;
};

get '/:post' => sub {
  use File::Fu;
  use Try::Tiny;
  use DateTime;

  my $fn = params->{post};
  $fn =~ s/_/ /g;

  my $error;
  my $file;
  try {
    $file = File::Fu->file(config->{appdir} . '/public/posts/' . $fn);
    $file->stat->mtime;
  } catch {
    status 'not_found';
    $error = "Nothing to see here.";
  };
  return $error if $error;

  my @posts = (
    { 
      updated => DateTime->from_epoch( epoch => $file->stat->mtime ),
      title   => $file->basename, 
      content => join("", $file->read),
      who     => getpwuid($file->stat->uid), 
    } 
  );

  foreach (@posts) { 
	$_->{content} =~ s/\n\n/<\/p><p>/g;
	$_->{content} = "<p>" . $_->{content} . "</p>"; 
    $_->{slug} = $_->{title};
    $_->{slug} =~ s/\s/_/g;
  } 

  template 'index', { posts => \@posts };
};

true;
