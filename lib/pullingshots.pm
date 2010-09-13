package pullingshots;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get qr{/(rdf|rss|atom).*} => sub {
use XML::Atom::SimpleFeed;
 
 my $feed = XML::Atom::SimpleFeed->new(
     title   => 'pullingshots',
     link    => 'http://pullingshots.ca/',
     link    => { rel => 'self', href => 'http://pullingshots.ca/atom', },
     updated => '2010-09-13T02:13:02Z',
     author  => 'Andrew Baerg',
     id      => 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6',
 );
 
 $feed->add_entry(
     title     => 'schooled',
     link      => 'http://pullingshots.ca/schooled',
     id        => 'urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a',
     summary   => q|
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
|,
     updated   => '2010-09-13T02:30:02Z',
     category  => 'Miscellaneous',
 );
 
  content_type 'application/xhtml+xml';

 $feed->as_string;
};

get qr{.*} => sub {

    warning 'base: ' . request->base . ' path: ' . request->path . ' client: ' . request->user_agent;
    template 'index';

};

true;
