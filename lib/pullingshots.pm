package pullingshots;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    warning request->base;
    template 'index';

};

get '/*' => sub {

    warning request->base . request->path;
    template 'index';

};

true;
