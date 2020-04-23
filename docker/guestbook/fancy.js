// Code adapted from W3Schools (RGB to HSL) and XOXCO (rainbow animation).
// For specifics, see:
// * https://www.w3schools.com/lib/w3color.js
// * https://github.com/xoxco/Rainbow-Text/blob/master/rainbow.js

redisApp.directive('fancy', ['$interval',
  function($interval) {
    var rainbow = function(){
      function rgbToHsl(r, g, b) {
        var min, max, i, l, s, maxcolor, h, rgb = [];
        rgb[0] = r / 255;
        rgb[1] = g / 255;
        rgb[2] = b / 255;
        min = rgb[0];
        max = rgb[0];
        maxcolor = 0;
        for (i = 0; i < rgb.length - 1; i++) {
          if (rgb[i + 1] <= min) {min = rgb[i + 1];}
          if (rgb[i + 1] >= max) {max = rgb[i + 1];maxcolor = i + 1;}
        }
        if (maxcolor == 0) {
          h = (rgb[1] - rgb[2]) / (max - min);
        }
        if (maxcolor == 1) {
          h = 2 + (rgb[2] - rgb[0]) / (max - min);
        }
        if (maxcolor == 2) {
          h = 4 + (rgb[0] - rgb[1]) / (max - min);
        }
        if (isNaN(h)) {h = 0;}
        h = h * 60;
        if (h < 0) {h = h + 360; }
        l = (min + max) / 2;
        if (min == max) {
          s = 0;
        } else {
          if (l < 0.5) {
            s = (max - min) / (max + min);
          } else {
            s = (max - min) / (2 - max - min);
          }
        }
        s = s;
        return {h : h, s : s, l : l};
      }

      function hslToRgb(hue, sat, light) {
        var t1, t2, r, g, b;
        hue = hue / 60;
        if ( light <= 0.5 ) {
          t2 = light * (sat + 1);
        } else {
          t2 = light + sat - (light * sat);
        }
        t1 = light * 2 - t2;
        r = Math.round(hueToRgb(t1, t2, hue + 2) * 255);
        g = Math.round(hueToRgb(t1, t2, hue) * 255);
        b = Math.round(hueToRgb(t1, t2, hue - 2) * 255);
        return {r : r, g : g, b : b};
      }

      function hueToRgb(t1, t2, hue) {
        if (hue < 0) hue += 6;
        if (hue >= 6) hue -= 6;
        if (hue < 1) return (t2 - t1) * hue + t1;
        else if(hue < 3) return t2;
        else if(hue < 4) return (t2 - t1) * (4 - hue) + t1;
        else return t1;
      }

      function updateHueOfRgb(rgb, hueInc) {
        rgb = rgb.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/);
        hsl = rgbToHsl(parseInt(rgb[1]), parseInt(rgb[2]), parseInt(rgb[3]));
        newRgb = hslToRgb(hsl.h + hueInc, .7, .6);
        return "rgb(" + newRgb.r + "," + newRgb.g + "," + newRgb.b + ")";
      }

      function setUp(elt, options) {
        options.originalText = elt.html();
  			elt.data('options', options);

        options.colors = ["rgb(255,0,0)"];
        for (i = 0; i < options.originalText.length; i++) {
        	newColor = rainbow.updateHueOfRgb(options.colors[i], options.colorIncrement);
        	options.colors.push(newColor);
        }

  			if (options.pad) {
  				for (x = 0; x < options.originalText.length; x++) {
  					options.colors.unshift(options.colors[options.colors.length-1]);
  				}
  			}

        render(elt, options);
      }

      function render(elt, options) {
        var chars = options.originalText.split('');

        var newstr = '';
        var counter = 0;
        for (var x in chars) {
  				if (chars[x]!=' ') {
  					newstr = newstr + '<span style="color: ' + options.colors[counter] + ';">' + chars[x] + '</span>';
  					counter++;
  				} else {
  					newstr = newstr + ' ';
  				}

  				if (counter >= options.colors.length) {
  					counter = 0;
  				}
  			}
        elt.html(newstr);
      }

      function shiftColor(elt) {
        var options = elt.data('options');

        var color = options.colors.pop();
        var newColor = updateHueOfRgb(color, options.colorIncrement);
    		options.colors.unshift(newColor);

        render(elt, options);
      }

      return {
        setUp: setUp,
        updateHueOfRgb: updateHueOfRgb,
        shiftColor: shiftColor,
      };
    }();

    return function(scope, element, attrs) {
      var stopChange;

      var options = {
        colorIncrement: 25,
        timeout: 70,
        pad: false,
      }

      rainbow.setUp(element, options);

      stopChange = $interval(function() { rainbow.shiftColor(element) }, options.timeout);

      element.on('$destroy', function() {
        $interval.cancel(stopChange);
      });
    }
  }
]);
