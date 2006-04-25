package Kwiki::HatenaAuth;
use strict;
use Hatena::API::Auth;

use Kwiki::UserName '-Base';
use mixin 'Kwiki::Installer';

our $VERSION = 0.01;

const class_id => 'user_name';
const class_title => 'Kwiki with HatenaAuth authentication';
const css_file => 'user_name.css';
const cgi_class => 'Kwiki::HatenaAuth::CGI';

field -package => 'Kwiki::PageMeta', 'edit_by_icon';

sub register {
    my $registry = shift;
    $registry->add(preload => 'user_name');
    $registry->add(action  => "return_hatenaauth");
    $registry->add(action  => "logout_hatenaauth");
    $registry->add(hook    => "page_metadata:sort_order", post => 'sort_order_hook');
    $registry->add(hook    => "page_metadata:update", post => 'update_hook');
}

sub sort_order_hook {
    my $hook = pop;
    return $hook->returned, 'edit_by_icon';
}

sub update_hook {
    my $meta = $self->hub->pages->current->metadata;
    $meta->edit_by_icon($self->hub->users->current->thumbnail_url);
}

sub return_hatenaauth {
    my %input = map { ($_ => scalar $self->cgi->$_) } qw(cert);
    my $user = $self->hatena_api_auth->login($input{cert});
    if ($user) {
        my %cookie = map { ($_ => scalar $user->$_) } qw(name image_url thumbnail_url);
        $self->hub->cookie->write(hatenaauth => \%cookie);
    }
    $self->redirect("?");
}

sub logout_hatenaauth {
    $self->hub->cookie->write(hatenaauth => {}, { -expires => "-3d" });
    $self->render_screen(content_pane => 'logout_hatenaauth.html');
}

sub hatena_api_auth {
    Hatena::API::Auth->new({
        api_key => $self->hub->config->hatenaauth_key,
        secret  => $self->hub->config->hatenaauth_secret,
    });
}
sub uri_to_login {
    $self->hatena_api_auth->uri_to_login->as_string;
}

package Kwiki::HatenaAuth::CGI;
use Kwiki::CGI '-Base';

cgi 'cert';

package Kwiki::HatenaAuth;

1;

__DATA__

=head1 NAME

Kwiki::HatenaAuth - Kwiki HatenaAuth integration

=head1 SYNOPSIS

  > $EDITOR plugins
  # Kwiki::UserName <- If you use it, comment it out
  Kwiki::HatenaAuth
  Kwiki::Edit::HatenaAuthRequired <- Optional: If you don't allow anonymous writes
  > $EDITOR config.yaml
  users_class: Kwiki::Users::HatenaAuth
  hatenaauth_key: PUT YOUR KEY HERE
  hatenaauth_secret: PUT YOUR SECRET KEY HEAR
  > kwiki -update

=head1 DESCRIPTION

Kwiki::HatenaAuth is a Kwiki User Authentication module to use HatenaAuth
authentication. You need a valid HatenaAuth API KEY registered at http://auth.hatena.ne.jp/

CallBack URL is 'BASE_URL'?action=return_hatenaauth

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

inspired by L<Kwiki::TypeKey>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Hatena::API::Auth> L<Kwiki::Edit::RequireUserName> L<Kwiki::Users::Remote>

=cut

__css/user_name.css__
div #user_name_title {
  font-size: small;
  float: right;
}
__template/tt2/user_name_title.html__
<!-- BEGIN user_name_title.html -->
<div id="user_name_title">
<em>[% IF hub.users.current.name -%]
(You are <a href="http://d.hatena.ne.jp/[% hub.users.current.name %]/">[% hub.users.current.name | html %]</a>: <a href="[% script_name %]?action=logout_hatenaauth">Logout</a>)
[%- ELSE -%]
(Not Logged In: <a href="[% hub.load_class('user_name').uri_to_login %]">Login via HatenaAuth</a>)
[%- END %]
</em>
</div>
<!-- END user_name_title.html -->
__template/tt2/logout_hatenaauth.html__
<!-- BEGIN logout_hatenaauth.html -->
<p>You've now successfully logged out.</p>
<!-- END logout_hatenaauth.html -->
__template/tt2/recent_changes_content.html__
<table class="recent_changes">
[% FOR page = pages %]
[% SET username = page.metadata.edit_by;
   SET icon = page.metadata.edit_by_icon %]
<tr>
    <td class="page_name">[% page.kwiki_link %]</td>
    <td class="edit_by_icon" style="text-align: right">[% IF icon %]<img class="edit-by-icon" src="[% icon %]" height="24" style="vertical-align:middle" align="right" />[% END %]</td>
    <td class="edit_by_left"><a href="http://d.hatena.ne.jp/[% username %]/">[% username %]</a></td>
    <td class="edit_time">[% page.edit_time %]</td>
</tr>
[% END %]
</table>
__theme/basic/template/tt2/theme_title_pane.html__
<div id="title_pane">
  <h1>
[% IF hub.users.current.image_url %]<a href="[% script_name %]?"><img src="[% hub.users.current.image_url %]" height="36" style="vertical-align: middle; border: 0" /></a>[% END -%]
  [% screen_title || self.class_title %]
  </h1>
</div>
__config/hatenaauth.yaml__
hatenaauth_key: PUT YOUR KEY HERE
hatenaauth_secret: PUT YOUR SECRET KEY HEAR
