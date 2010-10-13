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
    $fn =~ s/_/ /g;
    @files = $dir->find(sub{ /\/\Q$fn\E$/ });
  }
  else {
    @files = $dir->list;
  }

  my @posts;
  foreach (@files) {
    next if $_->is_dir;
    push @posts,  { 
      updated => DateTime->from_epoch( epoch => $_->stat->mtime ),
      title   => $_->basename, 
      content => join("", $_->read),
      who     => getpwuid($_->stat->uid), 
    }
  }

  foreach (@posts) {
    $_->{slug} = $_->{title};
    $_->{slug} =~ s/\s/_/g;
    $_->{slug} = uri_encode($_->{slug}, true);
    $_->{html} = markdown($_->{content});
  }

  @posts
}

sub images {
  use File::Fu;
  use DateTime;
  use URI::Encode qw(uri_encode uri_decode);

  my $dir = File::Fu->dir(config->{appdir} . '/public/posts/images/');
  my @files;

  my $fn = shift;
  if ($fn) {
    $fn = uri_decode($fn);
    $fn =~ s/_/ /g;
    @files = $dir->find(sub{ /\/\Q$fn\E\..+$/ });
  }
  else {
    @files = $dir->list;
  }

  my @images;
  foreach (@files) {
    next if $_->is_dir;
    push @images,  { 
      updated => DateTime->from_epoch( epoch => $_->stat->mtime ),
      filename   => $_->basename, 
      who     => getpwuid($_->stat->uid), 
    }
  }

  use Image::Thumbnail;
  my $res = shift || '600';
  my $thumbdir = File::Fu->dir(config->{appdir} . '/public/images/' . $res . '/');
  if (!$thumbdir->e) { $thumbdir->create; }
  foreach (@files) {
    if ($_->is_file) {
      my $thumbfn = $_->basename;
      my @thumb = $thumbdir->find(sub{ /\/\Q$thumbfn\E$/ });
      if (!@thumb) {
        my $t = new Image::Thumbnail(
                size       => $res,
                create     => 1,
		module     => "Image::Magick",
                input      => config->{appdir} . '/public/posts/images/' . $_->basename,
                outputpath => config->{appdir} . '/public/images/' . $res . '/' . $_->basename,
        );
      }
    }
  }

  foreach (@images) {
    $_->{title} = $_->{filename};
    $_->{title} =~ s/\..+$//;
    $_->{slug}  = $_->{title};
    $_->{slug}  =~ s/\s/_/g;
    $_->{slug}  = uri_encode($_->{slug}, true);
    $_->{html}  = "<p><a href='/images/posts/" . $_->{filename} . "'><img src='/images/$res/" . $_->{filename} . "' /></a></p>";
  }

  @images
}

get '/' => sub {

  my @posts = posts;

  template 'index', { posts => \@posts };
};

get qr{/index.*} => sub {

  my @posts = posts;

  template 'index', { posts => \@posts };
};

get qr{/(rdf|rss|atom).*} => sub {
  use XML::Atom::SimpleFeed;
  use File::Fu;
  use DateTime::Format::Atom;

  my @posts = posts;
  my @images = images;
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
  foreach (@images) {
    $feed->add_entry(
     title     => $_->{title},
     link      => uri_for('/images/' . $_->{slug}),
     id        => 'urn:uuid:' . $_->{slug},
     summary   => $_->{html},
     updated   => $fa->format_datetime($_->{updated}),
     category  => 'Miscellaneous',
    );
  }
 
  content_type 'application/xhtml+xml';

 $feed->as_string;
};

get '/images/' => sub {

  my @images = images('', '640');

  template 'image_index', { images => \@images, res => '640' };
};

get '/:post' => sub {

  my @posts = posts(params->{post});

  if (! scalar @posts) {
    status 'not_found';
    return "<a href=\"/\">Move along.</a> Nothing to see here.";
  }

  template 'index', { posts => \@posts };
};

get '/images/:image' => sub {

  my @images = images(params->{image}, 1024);

  if (! scalar @images) {
    status 'not_found';
    return "<a href=\"/\">Move along.</a> Nothing to see here.";
  }

  template 'image_index', { images => \@images, res => '1024' };
};

true;
