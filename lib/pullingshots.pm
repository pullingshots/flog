package pullingshots;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    warning request->base;
    template 'index';

};

get qr{/rss.*} => sub {
  use XML::Atom;
  use XML::Atom::Feed;
  use XML::Atom::Entry;
  use XML::Atom::Link;

  $XML::Atom::DefaultVersion = "1.0";

  content_type 'application/xhtml+xml';

   my $feed = XML::Atom::Feed->new;
    $feed->title('pullingshots');
    $feed->id('tag:pullingshots.ca,2010:1');
    my $entry = XML::Atom::Entry->new;
    $entry->title('schooled');
    $entry->id('tag:pullingshots.ca,2010:1');
    $entry->content(q|
<p>
September always feels a lot more like a new year than the New Year does. 
</p>
<p>
Here's a fresh new pullingshots.ca for the new New Year.
</p>
<p>
<a href="http://www.flickr.com/photos/baergaj/4943726575/" title="BLEEP! CLICK! ZAP! PING! by baergaj, on Flickr"><img src="http://farm5.static.flickr.com/4122/4943726575_da37debaaa.jpg" width="500" height="334" alt="BLEEP! CLICK! ZAP! PING!" /></a>
</p>
<p><i>p.s. If you're looking for the old pullingshots.ca or something else here... well... it's gone. You could complain to the <a href="mailto:andrew.baerg@gmail.com">webmaster</a>, but he'll just tell you the same thing.</i></p>
|);
    my $link = XML::Atom::Link->new;
    $link->type('text/html');
    $link->rel('alternate');
    $link->href('http://pullingshots.ca/schooled');
    $entry->add_link($link);
    $feed->add_entry($entry);
  $feed->as_xml;
};

get qr{.*} => sub {

    warning request->base . request->path;
    template 'index';

};

true;
