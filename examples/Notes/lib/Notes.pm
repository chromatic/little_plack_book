package Notes v1.0.0 {
    use Modern::Perl;
    use Dancer;
    use Template;

    get '/'      => sub { redirect '/index' };

    get '/index' => \&show_index;

    get qr{/read/(.*?)/?} => sub
    {
        my ($id) = splat;
        my $note = get_note( $id );
        return read_note( $id, $note );
    };

    get '/create' => sub
    {
        my $note     = params->{note};
        my $contents = params->{contents};
        return template 'create.tt', { note => $note, contents => $contents };
    };

    post '/store'       => \&process_store;
    post '/store/:note' => \&process_store;

    sub show_index
    {
        my @notes = sort { $a cmp $b } keys %{ session()->{Notes} };
        template 'index.tt', { notes => \@notes };
    }

    sub get_note
    {
        my $id = shift;
        return session()->{Notes}{$id};
    }

    sub process_store
    {
        my $note     = param( 'note' );
        my $contents = param( 'contents' );

        return store_note( $note, $contents ) if $note && $contents;
        return forward '/create', { note => $note, contents => $contents },
                                  { method => 'GET' };
    };

    sub read_note
    {
        my ($note, $contents) = @_;
        template 'read_note.tt', { note => $note, contents => $contents };
    }

    sub store_note
    {
        my ($id, $contents) = @_;
        my $notes           = session->{Notes};
        $notes->{$id}       = $contents;

        session Notes => $notes;
        template 'stored_note.tt', { note => $contents, id => $id };
    }
}

1;
