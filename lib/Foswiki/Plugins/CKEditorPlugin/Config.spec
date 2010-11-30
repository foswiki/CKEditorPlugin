# ---+ Extensions
# ---++ GenPDFPisaPlugin
# **PATH**
# xhtml2pdf executable including complete path
$Foswiki::cfg{Extensions}{GenPDFPisaPlugin}{xhtml2pdf} = '/usr/local/bin/xhtml2pdf';
# **BOOLEAN EXPERT**
# Whether to use pisa's inbuild css or a custom css file
$Foswiki::cfg{Extensions}{GenPDFPisaPlugin}{useextcss} = $TRUE;
# **PATH EXPERT**
# Custom css file including complete path. Leave blank for file shipped with GenPDFPisaPlugin.
$Foswiki::cfg{Extensions}{GenPDFPisaPlugin}{extcssfile} = '';
# **PATH EXPERT**
# Custom css file including complete path. Leave blank for file shipped with GenPDFPisaPlugin.
$Foswiki::cfg{Extensions}{GenPDFPisaPlugin}{extcssfileNum} = '';
1;
