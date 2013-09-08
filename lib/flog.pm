package flog;
use Dancer ':syntax';

our $VERSION = '0.1';

sub posts {
  use File::Fu;
  use DateTime;
  use Text::Markdown 'markdown';
  use URI::Encode qw(uri_encode uri_decode);

  my $dir = File::Fu->dir(config->{postsdir} . '/');
  return unless $dir->e;

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
    $_->{prefix} = '/';
    $_->{slug} = $_->{title};
    $_->{slug} =~ s/\s/_/g;
    $_->{slug} = uri_encode($_->{slug}, true);
    while ($_->{content} =~ /\n\!\[(\d+)\]\((.+)\)/) {
      my @image = images($2, $1);
      my $html = $image[0]->{html} || "";
      $_->{content} =~ s/\n\!\[\Q$1\E\]\(\Q$2\E\)/\n$html/;
    }
    $_->{html} = markdown($_->{content});
    $_->{html} =~ s/\<pre\>/\<pre class='prettyprint'\>/g;
  }

  sort { $b->{updated} <=> $a->{updated} } @posts
}

sub images {
  use File::Fu;
  use DateTime;
  use URI::Encode qw(uri_encode uri_decode);

  my $fn = shift;
  my $res = shift || '640';
  my $subdir = shift;

  my $prefix = '';
  my $dir;
  if ($subdir) {
    $prefix = $subdir . ' ';
    $dir = File::Fu->dir(config->{postsdir} . '/images/' . $subdir . '/');
  }
  else {
    $dir = File::Fu->dir(config->{postsdir} . '/images/');
  }
  return unless $dir->e;

  my @files;

  if ($fn) {
    $fn = uri_decode($fn);
    $fn =~ s/_/ /g;
    my @f = $dir->list;
    @f = sort { $b->stat->mtime <=> $a->stat->mtime } @f;
    my $prev_f;
    foreach (@f) {
      next if $_->is_dir;
      if (scalar @files) {
        $prev_f = $_;
        last;
      }
      my $test = $_;
      $test =~ s/_/ /g;
      if ($test =~ /\/\Q$fn\E\..+$/) {
        push @files, $_;
        push @files, $prev_f || $_;
      }
      $prev_f = $_;
    }
    push @files, $prev_f;
  }
  else {
    my @f = $dir->list;
    @f = sort { $b->stat->mtime <=> $a->stat->mtime } @f;
    foreach (@f) {
      next if $_->is_dir;
      push @files, $_;
    }
    splice @files, 10;
  }

  my @images;

  foreach (@files) {
    next if $_->is_dir;
    push @images,  { 
      updated => DateTime->from_epoch( epoch => $_->stat->mtime ),
      filename   => $_->basename, 
      who     => getpwuid($_->stat->uid), 
    };
  }

  my $postsdir = File::Fu->dir(config->{appdir} . '/public/images/posts/');
  if (!$postsdir->e) { $postsdir->create; }
  foreach (@files) {
    if ($_->is_file) {
      my $post_file = File::Fu->file(config->{appdir} . '/public/images/posts/' . $prefix . $_->basename);
      if (!$post_file->e) {
        $_->copy( $post_file );
      }
    }
  }

  use Image::Thumbnail;
  my $thumbdir = File::Fu->dir(config->{appdir} . '/public/images/' . $res . '/');
  if (!$thumbdir->e) { $thumbdir->create; }
  foreach (@files) {
    if ($_->is_file) {
      my $rotate = `jhead -autorot "$_"`;
      my $thumbfn = $prefix . $_->basename;
      my @thumb = $thumbdir->find(sub{ /\/\Q$thumbfn\E$/ });
      if (!@thumb) {
        my $t = new Image::Thumbnail(
                size       => $res,
                create     => 1,
		quality    => 70,
		#module     => "Image::Magick",
                input      => config->{appdir} . '/public/images/posts/' . $prefix . $_->basename,
                outputpath => config->{appdir} . '/public/images/' . $res . '/' . $prefix . $_->basename,
        );
      }
    }
  }

  foreach (@images) {
    $_->{prefix} = '/images/';
    $_->{title} = $_->{filename};
    $_->{title} =~ s/\..+$//;
    $_->{slug}  = $_->{title};
    $_->{slug}  =~ s/\s/_/g;
    $_->{slug}  = ($subdir) ? $subdir . '/' . uri_encode($_->{slug}, true) : uri_encode($_->{slug}, true);
    $_->{filename}  = uri_encode($prefix . $_->{filename}, true);
    $_->{html}  = "<p><a href='/images/" . $_->{slug} . "' title='" . $_->{title} . "'><img src='/images/$res/" . $_->{filename} . "' alt='" . $_->{title} . "' /></a></p>" if $res < 800;
    $_->{html}  = "<p><a href='/images/posts/" . $_->{filename} . "' title='" . $_->{title} . "'><img src='/images/$res/" . $_->{filename} . "' alt='" . $_->{title} . "' /></a></p>" if $res >= 800;
  }

  @images
}

sub audio {
  use File::Fu;
  use DateTime;
  use URI::Encode qw(uri_encode uri_decode);

  use Music::Tag;

  my $dir = File::Fu->dir(config->{postsdir} . '/audio/');
  return unless $dir->e;

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

  my @posts;
  foreach (@files) {
    next if $_->is_dir;
    my $info = Music::Tag->new($_, { quiet => 1 });
    $info->get_tag();
    push @posts,  {
      updated => DateTime->from_epoch( epoch => $_->stat->mtime ),
      filename   => $_->basename,
      info  => $info,
      who     => getpwuid($_->stat->uid),
    };
  }

  my $oggdir = File::Fu->dir(config->{appdir} . '/public/audio/ogg/');
  if (!$oggdir->e) { $oggdir->create; }
  my $mp3dir = File::Fu->dir(config->{appdir} . '/public/audio/mp3/');
  if (!$mp3dir->e) { $mp3dir->create; }
  foreach (@files) {
    if ($_->is_file) {
      my $base_fn = $_->basename;
      $base_fn =~ s/\.\w+$//;
      my @ogg = $oggdir->find(sub{ /\/\Q$base_fn\E\./ });
      if (!@ogg) {
	#my $touch = `touch $_`;
        my $ffmpeg = `ffmpeg -i "$_" -acodec vorbis -aq 30 "$oggdir$base_fn.ogg" >/dev/null 2>/dev/null </dev/null &`;
      }
      my @mp3 = $mp3dir->find(sub{ /\/\Q$base_fn\E\./ });
      if (!@mp3) {
	#my $touch = `touch $_`;
        my $ffmpeg = `ffmpeg -i "$_" -ab 128000 "$mp3dir$base_fn.mp3" >/dev/null 2>/dev/null </dev/null &`;
      }
    }
  }

  foreach (@posts) {
	    $_->{prefix} = '/audio/';
	    $_->{title} = $_->{filename};
	    $_->{title} =~ s/\.\w+$//;
	    my $ogg = $_->{title} . ".ogg";
	    my $mp3 = $_->{title} . ".mp3";
	    $_->{slug} = $_->{title};
	    $_->{slug} =~ s/\s/_/g;
	    $_->{slug} = uri_encode($_->{slug}, true);
	    my ($artist, $album, $title) = ($_->{info}->artist() || 'Unknown', $_->{info}->album() || 'Unknown', $_->{info}->title() || 'Unknown');
	    $_->{html} = qq|<p>
	<audio controls preload="none">
	  <source src="/audio/ogg/$ogg" />
	  <source src="/audio/mp3/$mp3" />
	</audio>|;
	    $_->{html} .= " <a href='/audio/mp3/$mp3' title='download mp3" . $_->{title} . "'><img id='audio-download' width='24' height='24' src='/images/dl_icon.png' /></a><br />";
	    $_->{html} .= qq|<strong><i>$title</i></strong> by <strong><i>$artist</i></strong> from the album <strong><i>$album</i></strong></p>|;
  }

  sort { $b->{updated} <=> $a->{updated} } @posts
}

get '/' => sub {

  my @posts = posts;

  template 'index', { page_title => 'Home', posts => \@posts };
};

get qr{/index.*} => sub {

  my @posts = posts;

  template 'index', { page_title => 'Home', posts => \@posts };
};

get qr{/(rdf|atom).*} => sub {
  use XML::Atom::SimpleFeed;
  use File::Fu;
  use DateTime::Format::Atom;
  use Data::UUID;

  my @posts = posts;
  my @images = images;
  my @audio = audio;
  my $fa = DateTime::Format::Atom->new();
  my $dir = File::Fu->dir(config->{postsdir});
  return unless $dir->e;

  my $updated = DateTime->from_epoch( epoch => $dir->stat->mtime );
  my $uuid = new Data::UUID;
  my $feed = XML::Atom::SimpleFeed->new(
     title   => config->{appname},
     link    => 'http://' . config->{domain} . '/',
     link    => { rel => 'self', href => 'http://' . config->{domain}, },
     updated => $fa->format_datetime($updated),
     author  => config->{author} || 'Unknown',
     id      => 'urn:uuid:' . $uuid->create_from_name_str(NameSpace_URL, config->{domain}),
  );

  foreach (sort { $b->{updated} <=> $a->{updated} } @posts, @images, @audio) {
    $feed->add_entry(
     title     => $_->{title},
     link      => uri_for($_->{prefix} . $_->{slug}),
     id        => 'urn:uuid:' . $uuid->create_from_name_str(NameSpace_URL, $_->{prefix} . $_->{slug} ),
     summary   => $_->{html},
     updated   => $fa->format_datetime($_->{updated}),
     category  => 'Miscellaneous',
    );
  }
 
  content_type 'application/xml';

 $feed->as_string;
};

get '/rss' => sub {
  use XML::RSS;
  use File::Fu;
  use DateTime::Format::RSS;
  use Data::UUID;

  my @posts = posts;
  my @images = images;
  my @audio = audio;
  my $fa = DateTime::Format::RSS->new();
  my $dir = File::Fu->dir(config->{postsdir});
  return unless $dir->e;

  my $updated = DateTime->from_epoch( epoch => $dir->stat->mtime );
  my $uuid = new Data::UUID;

  my $rss = XML::RSS->new (version => '2.0');
  $rss->channel(title          => config->{appname},
               link           => 'http://' . config->{domain},
               language       => 'en',
               description    => config->{tagline},
               pubDate        => $fa->format_datetime($updated),
               lastBuildDate  => $fa->format_datetime($updated),
               managingEditor => config->{author_email},
               webMaster      => config->{admin_email}
               );

  foreach (sort { $b->{updated} <=> $a->{updated} } @images) {
    $rss->image(title       => $_->{title},
             url         => uri_for($_->{prefix} . $_->{slug}),
             link        => uri_for($_->{prefix} . $_->{slug}),
             width       => 640,
             description => $_->{html},
             );
  }

  foreach (sort { $b->{updated} <=> $a->{updated} } @posts, @audio) {
    $rss->add_item(title => $_->{title},
        permaLink  => uri_for($_->{prefix} . $_->{slug}),
        description => $_->{html},
    );
  }

  content_type 'application/xml';

  $rss->as_string;
};

get '/images/' => sub {

  my @images = images('', '200');

  template 'image_index', { page_title => 'Images', images => \@images, res => '200' };
};

get '/images/:dir/' => sub {

  my @images = images('', '200', params->{dir});

  template 'image_index', { page_title => params->{dir}, images => \@images, res => '200' };
};

get '/audio/' => sub {

  my @files = audio;

  template 'audio_index', { page_title => 'Audio', files => \@files };
};

get '/:post' => sub {

  my @posts = posts(params->{post});

  if (! scalar @posts) {
    status 'not_found';
    return "<a href=\"/\">Move along.</a> Nothing to see here.";
  }

  template 'index', { page_title => $posts[0]->{title}, posts => \@posts };
};

get '/drafts/:post' => sub {

  my @posts = posts('drafts/' . params->{post});

  if (! scalar @posts) {
    status 'not_found';
    return "<a href=\"/\">Move along.</a> Nothing to see here.";
  }

  template 'index', { page_title => $posts[0]->{title}, posts => \@posts };
};

get '/images/:image' => sub {

  my @images = images(params->{image}, 800);

  if (! scalar @images) {
    status 'not_found';
    return "<a href=\"/\">Move along.</a> Nothing to see here.";
  }

  my @current;
  push @current, $images[0];
  my @previous;
  push @previous, $images[1];
  my @next;
  push @next, $images[2];

  template 'image_index', { page_title => $images[0]->{title}, images => \@current, previous_images => \@previous, next_images => \@next, res => '800' };
};

get '/images/:dir/:image' => sub {

  my @images = images(params->{image}, 800, params->{dir});

  if (! scalar @images) {
    status 'not_found';
    return "<a href=\"/\">Move along.</a> Nothing to see here.";
  }

  my @current;
  push @current, $images[0];
  my @previous;
  push @previous, $images[1];
  my @next;
  push @next, $images[2];

  template 'image_index', { page_title => $images[0]->{title}, images => \@current, previous_images => \@previous, next_images => \@next, res => '800' };
};

get '/audio/:file' => sub {

  my @files = audio(params->{file});

  if (! scalar @files) {
    status 'not_found';
    return "<a href=\"/\">Move along.</a> Nothing to see here.";
  }

  template 'audio_index', { page_title => $files[0]->{title}, files => \@files };
};

get '/meeting/:id' => sub {
  template 'meeting', { topic => params->{id} };
};

true;
