# See bottom of file for license and copyright information

package Foswiki::Plugins::CKEditorPlugin;

use strict;

use Assert;

our $VERSION           = '$Rev: 5860 (2009-12-28) $';
our $RELEASE           = '26 Apr 2010';
our $SHORTDESCRIPTION  = 'Integration of the CK WYSIWYG Editor';
our $NO_PREFS_IN_TOPIC = 1;

# Defaults for CKEPLUGIN_INIT and INIT_browser. Defined as our vars to
# allow other extensions to override them.
# PLEASE ENSURE THE PLUGIN TOPIC EXAMPLES ARE KEPT IN SYNCH!

our $defaultINIT = <<'HERE';
extraPlugins : "ckefilebrowser,foswiki,toolbars,wikitext,tableresize,qwikisave",
removePlugins : "toolbar,save",
enterMode : "1",
menu_groups : "clipboard,form,tablecell,tablecellproperties,tablerow,tablecolumn,table,anchor,link,image,flash,checkbox,radio,textfield,hiddenfield,imagebutton,button,select,textarea,code",
ckefilebrowserUploadUrl : "%SCRIPTURL%/rest/WysiwygPlugin/upload",
foswiki_secret_id : "%WYSIWYG_SECRET_ID%",
stylesSet : "modellaachen",
foswiki_vars : { PUBURLPATH : "%PUBURLPATH%", PUBURL : "%PUBURL%", WEB : "%WEB%", TOPIC : "%TOPIC%", ATTACHURL : "%ATTACHURL%", ATTACHURLPATH : "%ATTACHURLPATH%", VIEWSCRIPTURL : "%SCRIPTURL{view}%", SCRIPTSUFFIX: "%SCRIPTSUFFIX%", SCRIPTURL : "%SCRIPTURL%", SYSTEMWEB: "%SYSTEMWEB%", HTTP_HOST: "%HTTP_HOST%" },   	
toolbar_Full : [['WikiText','-','Source'],['Cut','Copy','Paste','PasteText','PasteFromWord','-','Print','SpellChecker','Scayt'],['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],['Maximize','ShowBlocks','-','About'],'/',['Bold','Italic','Underline','Strike','-','Subscript','Superscript'],['NumberedList','BulletedList','-','Outdent','Indent','Blockquote','CreateDiv'],['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],['wbdroplets','wblink','Link','Unlink','Anchor'],['Code','Document','Image','Table','HorizontalRule','Smiley','SpecialChar','PageBreak'],'/',['Styles','Format','Font','FontSize']],
toolbar_Basic : [['Save', 'Cancel'],['WikiText'],['Undo','Redo','-','Link','Unlink','-','Document','Image','Table'],'/',['Format','-','Bold','Italic','Underline','-','NumberedList','BulletedList','Outdent','Indent','-','Styles']],
toolbar : "Basic",
height : "400"
HERE

our %defaultINIT_BROWSER = (
    MSIE   => '',
    OPERA  => '',
    GECKO  => 'gecko_spellcheck : true',
    SAFARI => '',
);

use Foswiki::Func ();

my $query;

# Info about browser type
my %browserInfo;

sub initPlugin {
    $query = Foswiki::Func::getCgiQuery();
    return 0 unless $query;
    unless ( $Foswiki::cfg{Plugins}{WysiwygPlugin}{Enabled} ) {
        Foswiki::Func::writeWarning(
"CKEPlugin is enabled but WysiwygPlugin is not enabled. Both plugins must be installed and enabled for CKE."
        );
        return 0;
    }

    # Identify the browser from the user agent string
    my $ua = $query->user_agent();
    if ($ua) {
        $browserInfo{isMSIE} = $ua =~ /MSIE/;
        $browserInfo{isMSIE5}   = $browserInfo{isMSIE} && ( $ua =~ /MSIE 5/ );
        $browserInfo{isMSIE5_0} = $browserInfo{isMSIE} && ( $ua =~ /MSIE 5.0/ );
        $browserInfo{isMSIE6} = $browserInfo{isMSIE} && $ua =~ /MSIE 6/;
        $browserInfo{isMSIE7} = $browserInfo{isMSIE} && $ua =~ /MSIE 7/;
        $browserInfo{isGecko}  = $ua =~ /Gecko/;   # Will also be true on Safari
        $browserInfo{isSafari} = $ua =~ /Safari/;
        $browserInfo{isOpera}  = $ua =~ /Opera/;
        $browserInfo{isMac}    = $ua =~ /Mac/;
        $browserInfo{isNS7}  = $ua =~ /Netscape\/7/;
        $browserInfo{isNS71} = $ua =~ /Netscape\/7.1/;
    }

    return 1;
}

sub _notAvailable {
    for my $c qw(CKEPLUGIN_DISABLE NOWYSIWYG) {
        return
          "Disabled by * Set $c = " . Foswiki::Func::getPreferencesValue($c)
            if Foswiki::Func::getPreferencesFlag($c);
    }

    # Disable CKE if we are on a specialised edit skin
    my $skin = Foswiki::Func::getPreferencesValue('WYSIWYGPLUGIN_WYSIWYGSKIN');
    return "$skin is active"
      if ( $skin && Foswiki::Func::getSkin() =~ /\b$skin\b/o );

    return "No browser" unless $query;

    return "Disabled by URL parameter" if $query->param('nowysiwyg');

    # Check the client browser to see if it is blacklisted
    my $ua = Foswiki::Func::getPreferencesValue('CKEPLUGIN_BAD_BROWSERS')
      || '(?i-xsm:Konqueror)';
    return 'Unsupported browser: ' . $query->user_agent()
      if $ua && $query->user_agent() && $query->user_agent() =~ /$ua/;

    return 0;
}

sub beforeEditHandler {

    my ($text, $topic, $web) = @_;

    my $mess = _notAvailable();
    if ($mess) {
        if ( ( $mess !~ /^Disabled/ || DEBUG )
            && defined &Foswiki::Func::setPreferencesValue )
        {
            Foswiki::Func::setPreferencesValue( 'EDITOR_MESSAGE',
                'WYSIWYG could not be started: ' . $mess );
        }
        return;
    }
    if ( defined &Foswiki::Func::setPreferencesValue ) {
        Foswiki::Func::setPreferencesValue( 'EDITOR_HELP', 'CKEQuickHelp' );
    }

    my $init = Foswiki::Func::getPreferencesValue('CKEPLUGIN_INIT')
      || $defaultINIT;
    my $extras = '';

    # The order of these conditions is important, because browsers
    # spoof eachother
    if ( $browserInfo{isSafari} ) {
        $extras = 'SAFARI';
    }
    elsif ( $browserInfo{isOpera} ) {
        $extras = 'OPERA';
    }
    elsif ( $browserInfo{isGecko} ) {
        $extras = 'GECKO';
    }
    elsif ( $browserInfo{isMSIE} ) {
        $extras = 'MSIE';
    }
    if (!$extras) {
        $extras =
          Foswiki::Func::getPreferencesValue( 'CKEPLUGIN_INIT_' . $extras )
          || $defaultINIT_BROWSER{$extras};
        if ( defined $extras ) {
            $init = join( ',', ( split( ',', $init ), split( ',', $extras ) ) );
        }
    }

    require Foswiki::Plugins::WysiwygPlugin;

    $mess = Foswiki::Plugins::WysiwygPlugin::notWysiwygEditable( $_[0] );
    if ($mess) {
        if ( defined &Foswiki::Func::setPreferencesValue ) {
            Foswiki::Func::setPreferencesValue( 'EDITOR_MESSAGE',
                'WYSIWYG could not be started: ' . $mess );
        }
        return;
    }

    my $USE_SRC = '';
    if ( Foswiki::Func::getPreferencesValue('CKEPLUGIN_DEBUG') ) {
        $USE_SRC = '_src';
    }

    # Add the Javascript for the editor. When it starts up the editor will
    # use a REST call to the WysiwygPlugin tml2html REST handler to convert
    # the textarea content from TML to HTML.
    my $pluginURL = '%PUBURL%/%SYSTEMWEB%/CKEditorPlugin';
    my $tmceURL   = $pluginURL . '/ckeditor';

    # expand and URL-encode the init string
    my $metainit = Foswiki::Func::expandCommonVariables($init);
    $metainit =~ s/([^0-9a-zA-Z-_.:~!*'\/%])/'%'.sprintf('%02x',ord($1))/ge;
    my $behaving;
    eval {
        require Foswiki::Contrib::BehaviourContrib;
        if ( defined(&Foswiki::Contrib::BehaviourContrib::addHEAD) ) {
            Foswiki::Contrib::BehaviourContrib::addHEAD();
            $behaving = 1;
        }
    };
    unless ($behaving) {
        Foswiki::Func::addToHEAD( 'BEHAVIOURCONTRIB',
'<script type="text/javascript" src="%PUBURLPATH%/%SYSTEMWEB%/BehaviourContrib/behaviour.js"></script>'
        );
    }
    # URL-encode the version number to include in the .js URLs, so that the browser re-fetches the .js
    # when this plugin is upgraded.
    my $encodedVersion = $VERSION;
    # SMELL: This regex (and the one applied to $metainit, above) duplicates Foswiki::urlEncode(),
    #        but Foswiki::Func.pm does not expose that function, so plugins may not use it
    $encodedVersion =~ s/([^0-9a-zA-Z-_.:~!*'\/%])/'%'.sprintf('%02x',ord($1))/ge;
    #Alex: Hier war der addToHead abschnitt - ggf. wieder zurück schreiben
    #my $zufall = time();
    
   	Foswiki::Func::addToZone('head', 'tiny', <<"META" );
	<meta name="CKEPLUGIN_INIT" content="$metainit" />
META
    
    Foswiki::Func::addToZone('script', 'tiny', <<"SCRIPT" );
<script language="javascript" type="text/javascript" src="%PUBURLPATH%/%SYSTEMWEB%/CKEditorPlugin/ckeditor/ckeditor.js"></script>
<script language="javascript" type="text/javascript" src="%PUBURLPATH%/%SYSTEMWEB%/CKEditorPlugin/ckeditor/_source/core/ajax.js"></script>
<script language="javascript" type="text/javascript" src="%PUBURLPATH%/%SYSTEMWEB%/CKEditorPlugin/ckeditor/foswiki_cke.js"></script>
<script language="javascript" type="text/javascript" src="%PUBURLPATH%/%SYSTEMWEB%/CKEditorPlugin/ckeditor/plugins/autosuggest/js/bsn.AutoSuggest_2.1.3.js"></script>
<link rel="stylesheet" href="%PUBURLPATH%/%SYSTEMWEB%/CKEditorPlugin/ckeditor/plugins/autosuggest/css/autosuggest_inquisitor.css" type="text/css" media="screen" charset="utf-8" />
SCRIPT

	Foswiki::Func::addToZone('ckscript', 'tiny', <<"SCRIPT" );
<script language="javascript" type="text/javascript" src="%PUBURLPATH%/%SYSTEMWEB%/CKEditorPlugin/ckeditor/foswiki.js"></script>
SCRIPT

    # See %SYSTEMWEB%.IfStatements for a description of this context id.
    Foswiki::Func::getContext()->{textareas_hijacked} = 1;
}

1;
__DATA__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2010 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights apply to some or all of the code in this file:

Copyright (C) 2010 Modell Aachen UG http://www.modell-aachen.de. 
All Rights Reserved. 

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.

