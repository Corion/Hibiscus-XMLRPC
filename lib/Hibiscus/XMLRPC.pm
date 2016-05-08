package Hibiscus::XMLRPC;
use strict;
use Moo 2; # or Moo::Lax if you can't have Moo v2
#use Filter::signatures;
no warnings 'experimental';
use feature 'signatures';
use URI;
use XMLRPC::PurePerl;

has 'ua' => (
    is => 'rw',
    default => sub { require Future::HTTP::Tiny; Future::HTTP::Tiny->new },
);

has 'url' => (
    is => 'rw',
    default => 'https://127.0.0.1:8080/xmlrpc',
);

sub call($self,$method,@params) {
    my $payload = $self->encode_request($method,@params);
    $self->ua->post($self->url, {
        headers => {
            'Content-Type' => 'text/xml',
        },
        content => $payload,
    })->then(sub($result) {
        Future->done(
            $self->decode_result($result)
        );
    });
}

sub encode_request($self,$method,@params) {
    XMLRPC::PurePerl->encode_call_xmlrpc($method,@params)
}

sub decode_result($self,$result) {
    XMLRPC::PurePerl->decode_xmlrpc($result->{content})
}

sub BUILD($class, $args) {
    
    # Upgrade strings to URI::URL
    if( ! ref $args->{ url }) {
        $args->{ url } = URI->new( $args->{ url } );
    };
    
    if( defined( my $user = delete $args->{ user })) {
        $args->{ url }->user( $user );
    };
    if( defined( my $pass = delete $args->{ password })) {
        $args->{ url }->password( $pass );
    };
}

=head2 C<< ->transactions %filter >>

    my $transactions = $jameica->transactions(
        {
         "datum:min" => '2015-01-01', # or '01.01.2015'
         'datum:max' => '2015-12-31', # or '31.12.2015'
        }
    )->get;

Fetches all transactions that match the given filter and returns
them as an arrayref. If no filter is given, all transactions are returned.

The keys for each transaction are:

    {
      'konto_id' => '99',
      'betrag' => '-999,99',
      'gvcode' => '835',
      'zweck' => 'Zins   999,99 Tilg  999,99',
      'datum' => '2016-04-29',
      'customer_ref' => 'NONREF',
      'valuta' => '2016-04-30',
      'id' => '657',
      'umsatz_typ' => 'Kredit',
      'empfaenger_name' => 'IBAN ...',
      'saldo' => '99999.99'
    },

See L<https://www.willuhn.de/wiki/doku.php?id=develop:xmlrpc:umsatz>
for the list of allowed parameters.

=cut

sub transactions($self, %filter) {
    $self->call(
        'hibiscus.xmlrpc.umsatz.list',
        \%filter
    )
}

1;

__END__

=head1 INSTALLATION

=over 4

=item 1

Install Jameica and Hibiscus from
L<http://www.willuhn.de/products/hibiscus/>

=item 2

From within the application, install the
C<hibiscus.xmlrpc> plugin and all its prerequisites.
Restart after every prerequisite.

Yes. CPAN is much more convenient here.

=item 3

Under "File" -> "Preferences" (C<CTRL+E>), configure
C<hibiscus.xmlrpc.umsatz> to be enabled.

=item 4

Restart Jameica once more

=head1 SEE ALSO

L<https://www.willuhn.de/wiki/doku.php?id=develop:xmlrpc>

=back
