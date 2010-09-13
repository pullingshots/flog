package pullingshots;
use Dancer ':syntax';
use Dancer::Plugin::Email

our $VERSION = '0.1';

get '/' => sub {
    email {
            to => 'andrew.baerg@gmail.com',
            subject => 'pullingshots.ca: another request',
            message => request->base,
        };


    template 'index';

};

get '/*' => sub {
    email {
            to => 'andrew.baerg@gmail.com',
            subject => 'pullingshots.ca: another request',
            message => request->base,
        };


    template 'index';

};

true;
