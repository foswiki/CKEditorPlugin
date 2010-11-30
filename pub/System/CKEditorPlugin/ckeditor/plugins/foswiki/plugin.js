

//Alex: Funktionen für das Plugin	
var numberRegex = /^\d+(?:\.\d+)?$/,
	code1Regex = /%.*\{.*\}%$/g,
	codeRegex = /^%[\s\S]*%$/ig;

var cssifyLength = function( length )
	{
		if ( numberRegex.test( length ) )
			return length + 'px';
		return length;
	};
	
var getLink = function( element )
	{
		//var linkRegex = new RegExp("\[\[([^\]]*)\]\[([^\]]*)\]\]", "ig");

	    //alert(element);
		//var linkRegex = new RegExp("\[\[([\s\S]*)", "ig");
		
		var ausdruck1 = /([\s\S]*)/g;
		if (ausdruck1.test(element))
		{
			var result = ausdruck1.exec(element);
			alert(result);
			var name = result[0] || 'fehler';
			var href = result[0] || 'fehler';
		}
		//alert(element + "und ist  :" + wert);
		
		var attributes = { name: name || 'fehler', href: href || 'fehler' };
		return attributes;
		//return ( wert );
	};
	
var isCode = function( element )
	{
		//alert("Element: " + element + "ist: " + codeRegex.test( element ));
		return ( codeRegex.test( element ) );
	};


CKEDITOR.plugins.add('foswiki',
{
	requires : [ 'dialog', 'fakeobjects'],

	init : function( editor, pluginPath )
	{
	
	
		//Dokumente Verlinken
		editor.addCommand( 'document', new CKEDITOR.dialogCommand( 'document' ) );
		editor.ui.addButton( 'Document',
			{
				//label : editor.lang.document.toolbar,
				label	: editor.lang.document.toolbar,
				command : 'document',
				icon	: this.path + 'images/document.gif'
			});
		CKEDITOR.dialog.add( 'document', this.path + 'dialogs/document.js' );

		//Code Einbinden
		//Alex: Anpassen
		editor.addCommand( 'code', new CKEDITOR.dialogCommand( 'code' ) );
		editor.ui.addButton( 'Code',
			{
				label : editor.lang.code.toolbar,
				command : 'code',
				icon	: this.path + 'images/code.png'
			});
		
		CKEDITOR.dialog.add( 'code', this.path + 'dialogs/code.js' );
		
		//Alex: Css für das Code FakeImage
		editor.addCss(
				'img.cke_code' +
				'{' +
					'background-image: url(' + CKEDITOR.getUrl( this.path + 'images/code_tag.gif' ) + ');' +
					'background-position: center center;' +
					'background-repeat: no-repeat;' +
					'border: 1px solid #a9a9a9;' +
					'width: 80px;' +
					'height: 20px;' +
				'}'
				);


		
		// If the "menu" plugin is loaded, register the menu items.
		if ( editor.addMenuItems )
		{
			editor.addMenuItems(
				{		
					code :
					{
						label : "Code",
						command : 'code',
						group : 'code',
						order : 1
					}
				});
		}
		
		
		if ( editor.contextMenu )
		{		
			//Alex: code contextmenu
			editor.contextMenu.addListener( function( element, selection )
				{
					if ( element && element.is( 'img' ) && element.getAttribute( '_cke_real_element_type' ) == 'code' )
						return { code : CKEDITOR.TRISTATE_OFF };
				});
			

		}
	},
	
	afterInit : function( editor )
	{
		var dataProcessor = editor.dataProcessor,
			dataFilter = dataProcessor && dataProcessor.dataFilter,
			htmlFilter = dataProcessor && dataProcessor.htmlFilter;
		
		
		if ( dataFilter )
		{
			dataFilter.addRules(
				{
					elements :
					{
						//Alex: Hier werden alle Span´s gefiltert und nach Code durchsucht
					    span : function( element )
						{
							//Alex: Due to lovely Internet Explorer
							var attr = '';							
							attr = element.attributes["class"];
							
							if (attr == "WYSIWYG_PROTECTED")
							{
								for ( var i = 0 ; i < element.children.length ; i++ )
								{
									var value = element.children[ i ].value;
									value = value.replace(/\n/, '');
								
									var el;
									
									if ( isCode(value) )
									{
										return editor.createFakeParserElement( element, 'cke_code', 'code');
									}
									else
										return editor.createFakeParserElement( element, 'cke_code', 'code');
										
									return;

								}
							}
						}
					}
				});
		}
		
		if ( htmlFilter )
		{
			htmlFilter.addRules(
				{
					elements :
					{
						//Alex: Hier werden alle Span´s gefiltert und nach Code durchsucht
					    span : function( element )
						{
							//Alex: Due to lovely Internet Explorer
							var attr = '';							
							attr = element.attributes["class"];
							if (attr == "WYSIWYG_PROTECTED")
							{
								for ( var i = 0 ; i < element.children.length ; i++ )
								{
									var value = element.children[ i ].value;
									value = value.replace(/\n/, '');

									if ( isCode(value) )
									{
									}
									return element;

								}
							}		
						}
					}
				});
		}
	}
} );


CKEDITOR.editor.prototype.createFakeParserElement = function( realElement, className, realElementType, isResizable, imgSrc )
{
var lang = this.lang.fakeobjects,
	html;

var writer = new CKEDITOR.htmlParser.basicWriter();
realElement.writeHtml( writer );
html = writer.getHtml();


var attributes =
{
	'class' : className,
	src : CKEDITOR.getUrl( 'images/spacer.gif' ) ,
	_cke_realelement : encodeURIComponent( html ),
		_cke_real_node_type : realElement.type,
		alt : lang[ realElementType ] || lang.unknown,
		align : realElement.attributes.align || ''
};
 
	if ( realElementType )
		attributes._cke_real_element_type = realElementType;

	if ( isResizable )
		attributes._cke_resizable = isResizable;
	
	if ( imgSrc )
	{
		//Alex: Hier muss gecheckt werden, ob das einwandfrei funzt, oder ob der Name noch überprüft werden muss
		attributes.src = CKEDITOR.getUrl( imgSrc );
		//alert(attributes.src);
	}

	return new CKEDITOR.htmlParser.element( 'img', attributes );
};




