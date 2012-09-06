String.prototype.ucwords = function() {
	return (this + '').replace(/^(.)|\s(.)/g, function ( a ) { return a.toUpperCase( ); } );
}

var infos = {
	"youtube": {
		"size": [560, 340],
		"embed": "http://www.youtube.com/v/#CODE#?fs=1&hd=1",
		"footer": "<br /><a href=\"http://www.youtube.com/watch?v=#CODE#\" target=\"_blank\">Veure'l a YouTube</a><br />",
		"params": {
			"allowFullScreen": "true",
			"wmode": "transparent",
			"allowscriptaccess": "always"
		},
		"url": "https?:\/\/(www\.)?youtube\.com\/watch",
		"split": "v=",
		"external": true
	},
	"youtu.be": {
		"size": [560, 340],
		"embed": "http://www.youtube.com/v/#CODE#?fs=1&hd=1",
		"footer": "<br /><a href=\"http://www.youtube.com/watch?v=#CODE#\" target=\"_blank\">Veure'l a YouTube</a><br />",
		"params": {
			"allowFullScreen": "true",
			"wmode": "transparent",
			"allowscriptaccess": "always"
		},
		"url": "https?:\/\/(www\.)?youtu\.be",
		"split": "/",
		"external": true
	},
	"youtube_pl": {
		"size": [560, 340],
		"embed": "http://www.youtube.com/p/#CODE#?hl=en_US&fs=1&hd=1",
		"footer": "<br /><a href=\"http://www.youtube.com/view_play_list?p=#CODE#\" target=\"_blank\">Veure-ho tot a YouTube</a><br />",
		"params": {
			"allowFullScreen": "true",
			"wmode": "transparent",
			"allowscriptaccess": "always"
		},
		"url": "https?:\/\/(www\.)?youtube\.com\/view_play_list",
		"split": "p=",
		"external": true
	},
	"vimeo":	{
		"size": [560, 340],
		"embed": "http://vimeo.com/moogaloop.swf?clip_id=#CODE#&amp;server=vimeo.com&amp;show_title=0&amp;show_byline=0&amp;show_portrait=0&amp;color=ff9933&amp;fullscreen=1",
		"footer": "<br /><a href=\"http://www.vimeo.com/#CODE#\" target=\"_blank\">Veure'l a Vimeo</a><br />",
		"params": {
			"allowFullScreen": "true",
			"wmode": "transparent",
			"allowscriptaccess": "always"
		},
		"url": "https?:\/\/(www\.)?vimeo\.com\/",
		"split": "/",
		"external": true
	},
	"goear":	{
		"size": [353, 132],
		"embed": "http://www.goear.com/files/external.swf?file=#CODE#",
		"flashvars": {
			"wmode": "transparent",
			"quality": "high"
		},
		"url": "http:\/\/(www\.)?goear\.com\/listen\/",
		"split": "/listen/",
		"external": true
	},
	"gvideo" : {
		"size": [560, 340],
		"embed": "http://video.google.com/googleplayer.swf?docid=#CODE#",
		"footer": "<br /><a href=\"http://video.google.es/videoplay?docid=#CODE#\" target=\"_blank\">Veure'l a Google Video</a><br />",
		"flashvars": {
			"allowFullScreen": "true",
			"wmode": "transparent",
			"allowscriptaccess": "always"
		},
		"url": "http:\/\/video\.google\.com\/",
		"split": "docid=",
		"external": true
	},
	"liveleak" : {
		"size": [560,340],
		"embed": "http://www.liveleak.com/e/#CODE#",
		"footer": "<br /><a href=\"http://www.liveleak.com/view?i=#CODE#\" target=\"_blank\">Veure'l a liveleak</a><br />",
		"flashvars": {
			"wmode" : "transparent"
		},
		"url": "http:\/\/(www\.)?liveleak\.com\/",
		"split": "i=",
		"external": true
	},
	"metacafe" : {
		"size" : [560, 340],
		"embed" : "http://www.metacafe.com/fplayer/#CODE#.swf",
		"footer": "<br /><a href=\"http://www.metacafe.com/watch/#CODE#\" target=\"_blank\">Veure'l a Metacafe</a><br />",
		"flashvars": {
			"playervars": "showStats=no|autoPlay=no"
		},
		"url" : "http:\/\/(www\.)?metacafe\.com\/",
		"split": "watch/",
		"external": true
	},
	"soundcloud": {
		"size" : ["100%", 81],
		"embed": "http://player.soundcloud.com/player.swf?url=#CODE#&amp;show_comments=true&amp;auto_play=false&amp;color=FF6600",
		"footer": "<span><a href=\"#CODE#\" target=\"_blank\">#TRACK#</a> by <a href=\"#ARTIST_URL#\" target=\"_blank\">#ARTIST#</a></span><br />",
		"flashvars": {
			"wmode": "transparent"
		},
		"url": "http:\/\/(www\.)?soundcloud\.com\/",
		"split": "/",
		"external": false,
		"artist_split": 2,
		"track_split": 1
	},
	"mixcloud" : {
		"size": [480, 250],
		"embed": "http://www.mixcloud.com/media/swf/player/mixcloudLoader.swf?feed=#CODE#",
		"footer": "<br /><span><a href=\"#CODE#\" target=\"_blank\">#TRACK#</a> by <a href=\"#ARTIST_URL#\" target=\"_blank\">#ARTIST#</a></span><br />",
		"flashvars": {
			"allowFullScreen": true,
			"wmode": "opaque",
			"allowscriptaccess": "always"
		},
		"url": "https?:\/\/(www\.)?mixcloud\.com\/",
		"split" : "/",
		"external": false,
		"artist_split": 3,
		"track_split": 2
	},
	"veoh" : {
		"size": [560, 340],
		"embed": "http://www.veoh.com/veohplayer.swf?permalinkId=#CODE#&id=anonymous&player=videodetailsembedded&affiliateId=&videoAutoPlay=0",
		"footer": "<br /><a href=\"http://www.veoh.com/videos/#CODE#\" target=\"_blank\">Veure'l a Veoh</a><br />",
		"url": "http:\/\/(www\.)?veoh\.com\/",
		"split": "/",
		"external": true
	},
	"dailymotion" : {
		"size": [560, 340],
		"embed": "http://www.dailymotion.com/swf/video/#CODE#",
		"footer": "<br /><a href=\"http://www.dailymotion.com/video/#CODE#\" target=\"_blank\">Veure'l a DailyMotion</a><br />",
		"url": "http:\/\/(www\.)?dailymotion\.com\/",
		"flashvars": {
			"allowFullScreen": "true",
			"wmode": "transparent",
			"allowscriptaccess": "always"
		},
		"split" : "video/",
		"external": true
	},
	"mp3": {
		"size": [350, 22],
		"embed": "http://underave.net/barna23/flash/player_mp3_maxi.swf",
		"footer": "<br /><a href=\"#CODE#\" target=\"_blank\" title=\"Botó dret, desar com a...\">Descarregar</a><br />",
		"flashvars": {
			"mp3": "#CODE#",
			"width" : 350,
			"height": 22,
			"showstop" : 1,
			"showvolume" : 1,
			"volumeheight" : 7,
			"skin" : "http%3A//forums.underave.net/images/mp3player.jpg",
			"loadingcolor" : "B56700",
			"bgcolor" : 222222,
			"bgcolor1" : 222222,
			"bgcolor2" : 222222,
			"sliderovercolor" : "B56700",
			"buttonovercolor" : "B56700"
		},
		"params": {
			"movie": "http://underave.net/music/anarchy_media/player_mp3_maxi.swf",
			"bgcolor": "#222222",
		},
		"url": "(.+)\.mp3$",
		"external": false
	}
};
var embedCount = 0, footer;

function embedMedia(url) {
	embedCount++;
	document.write('<div id="embed-' + embedCount + '"></div>');
	var found = false;
	$.each(infos, function(i, el) {
		if ( url.match(el.url) ) {
			if (typeof el.footer != 'undefined') {
				footer = el.footer;
			} else footer = 'undefined';

			var code = url;
			var embed = el.embed;
			if ( el.external == true ) {
				code = url.split(el.split)[url.split(el.split).length - 1];
				if ( i != "veoh" ) {
					code = code.split(/&|#/)[0];
				} else {
					code = code.split(/&|\/|#/);
					code.forEach(function(a){
						if ( a.match(/watch%3D/ig) ) {
							code = a.replace(/watch%3D/i, "");
						}
					});
				}
				embed = el.embed.replace(/#CODE#/ig, code);
			} else {
				if ( i == "mp3" ) {
					$.each(el.flashvars, function(k, e) {
						if ( new String(e).match(/#CODE#/) ) {
							el.flashvars[k] = e.replace(/#CODE#/ig, code);
						}
					});
				} else {
					// soundcloud && mixcloud
					var artist = code.split("/")[code.split("/").length - el.artist_split].replace(/-/ig," ").ucwords();
					var track = code.split("/")[code.split("/").length - el.track_split].replace(/-/ig," ").ucwords();
					var artist_url = code.replace(code.split("/")[code.split("/").length - el.track_split], "").replace(/\/$/, '');
					footer = footer
						.replace(/#TRACK#/ig, track)
						.replace(/#ARTIST_URL#/ig, artist_url)
						.replace(/#ARTIST#/ig, artist)
						.replace(/#CODE#/ig, code);
					embed = el.embed.replace(/#CODE#/ig, encodeURIComponent(code.replace(/#CODE#/ig, code)));
				}
			}
			swfobject.embedSWF(embed, "embed-" + embedCount, el.size[0], el.size[1], "10.0.0", "/js/swfobject/expressInstall.swf", el.flashvars || {}, el.params || {});
			// if ( typeof el.footer != "undefined" ) {
				document.write(footer.replace(/#CODE#/ig, code));
			// }
			found = true;
		}
	});
	if ( found === false ) {
		document.write("<p style=\"color:#FF8000; font-weight: bold\">El mitj&agrave; no s'ha pofut inserir. Verifica que la url sigui correcta<br />El medio no se ha podido insertar. Verifica que la url sea correcta.</p>");
	}
}
