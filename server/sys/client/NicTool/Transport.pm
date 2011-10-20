#!/usr/bin/perl
###
# Transport.pm
# Support class and factory for different Transport types
# $Id: Transport.pm 347 2004-12-10 03:13:38Z matt $
###
#
# NicTool v2.00-rc1 Copyright 2001 Damon Edwards, Abe Shelton & Greg Schueler
# NicTool v2.01 Copyright 2004 The Network People, Inc.
#
# NicTool is free software; you can redistribute it and/or modify it under
# the terms of the Affero General Public License as published by Affero,
# Inc.; either version 1 of the License, or any later version.
#
# NicTool is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the Affero GPL for details.
#
# You should have received a copy of the Affero General Public License
# along with this program; if not, write to Affero Inc., 521 Third St,
# Suite 225, San Francisco, CA 94107, USA
#
###

package NicTool::Transport;

sub new {
    my $pkg = shift;
    my $nt  = shift;
    bless { nt => $nt }, $pkg;
}

sub _nt {
    return $_[0]->{'nt'};
}

sub get_transport_agent {
    my ( $pkg, $protocol, $nt ) = @_;
    my $dp = uc($protocol);
    $dp =~ s/_//g;
    my $trans;
    eval qq(use NicTool::Transport::$dp);
    if ($@) {
        die
            "Unable to use class NicTool::Transport::$dp for data protocol '$protocol' : $@";
    }
    eval qq( \$trans = NicTool::Transport::$dp->new(\$nt));
    if ($@) {
        die
            "Unable to instantiate class NicTool::Transport::$dp for data protocol '$protocol' : $@";
    }
    return $trans;
}

sub _check_setup {
    my $self    = shift;
    my $message = 'OK';
    $message = "ERROR: server_host not set"
        unless ( $self->_nt->{server_host} );
    $message = "ERROR: server_port not set"
        unless ( $self->_nt->{server_port} );
    if ( $self->_nt->{use_https_authentication} ) {
        $message
            = "ERROR: client certificate (client_certificate_file) not set"
            unless ( $self->_nt->{client_certificate_file} );
        $message = "ERROR: client key file (client_key_file) not set"
            unless ( $self->_nt->{client_key_file} );
        if ( $self->_nt->{use_https_peer_authentication} ) {
            $message
                = "ERROR: CA certificate file or directory (ca_certificate_path or ca_certificate_file) not set"
                unless ( $self->_nt->{ca_certificate_path}
                || $self->_nt->{ca_certificate_file} );
        }
    }

    return $message;
}

sub _send_request {
    my $self = shift;
    my $url;
    my $msg = $self->_check_setup;

    if ( $msg ne 'OK' ) {
        return { 'error_code' => 'XXX', 'error_msg' => $msg };
    }
    if ( $self->_nt->{use_https_authentication} ) {
        $url
            = 'https://'
            . $self->_nt->{server_host} . ':'
            . $self->_nt->{server_https_port};
    }
    else {
        $url
            = 'http://'
            . $self->_nt->{server_host} . ':'
            . $self->_nt->{server_port};
    }

    #my $func = 'send_'.$self->_nt->{data_protocol}.'_request';
    if ( $self->can('send_request') ) {
        return $self->send_request( $url, @_ );
    }
    else {
        return {
            'error_code' => 501,
            'error_msg'  => 'Data protocol not supported: '
                . $self->_nt->{data_protocol}
        };
    }
}
1;