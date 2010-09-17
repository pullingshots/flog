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
     updated => '2010-09-17T02:13:02Z',
     author  => 'Andrew Baerg',
     id      => 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6',
 );
 
 $feed->add_entry(
     title     => 'schooled',
     link      => 'http://pullingshots.ca/schooled',
     id        => 'urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6b',
     summary   => q|
<p>
September always feels a lot more like a new year than the New Year does.
</p>
<p>
Here's a fresh new pullingshots.ca for the new New Year. It's running
on a <a href="http://www.disklessworkstations.com/200118.html?id=pX6fEGwb">new machine</a> (an old Dell machine from 2000 had faithfully served up eureca.ca, baerg.ca, and pullingshots.ca for many years),
in a <a href="http://www.flickr.com/photos/baergaj/4997509575/">new location</a> (previously in my office),
with a <a href="http://www.ubuntu.com/desktop">new OS</a> (I am embarrassed to admit I had still been using RedHat 7.2),
and using a <a href="http://perldancer.org">new framework</a> (I had been using a crufty old php based blog).
That's a lot of newness!
</p>
<p>
<a href="http://www.flickr.com/photos/baergaj/4943726575/" title="BLEEP! CLICK! ZAP! PING! by baergaj, on Flickr"><img src="http://farm5.static.flickr.com/4122/4943726575_da37debaaa.jpg" width="500" height="334" alt="BLEEP! CLICK! ZAP! PING!" /></a>
</p>
<p><i>p.s. If you're feeling nostalgic, here's <a href="http://pullingshots.ca:8081/">the old pullingshots.ca</a></i></p>
|,
     updated   => '2010-09-17T02:30:02Z',
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
