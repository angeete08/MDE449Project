# Stride artwork

`logo1.png` and `logo2.png` are format conversions of the original transparent TIFF files from `angeete08/MDE449Project`, branch `logos`, commit `4c8ab57`. Their artwork and original canvas dimensions are preserved.

The upper-left header shows only the STRIDE lettering underneath Logo 1. Logo 2's athlete replaces the hero illustration on the right. CSS background windows select those regions of the original canvases, preserving the capital S's upper curve, so no lettering or illustration is recreated.

Source: https://github.com/angeete08/MDE449Project/tree/4c8ab57

The current background is `brush-paint-texture.png`, an original generated texture based on the user's brush-stroke style references. It has genuine alpha transparency, dry-brush scratches, broken edges, detached spatters, and patchy olive-to-dark-green coloring. Both the wordmark and hero logo use it; their original logo artwork is unchanged. `brush-smear.svg` and `spray-paint.svg` are earlier, unused vector studies.

Both paint backgrounds are mirrored left-to-right in CSS to move the darker areas behind the bright logo. Only the background layers flip; the wordmark and athlete keep their original orientation.

The hero paint layer is additionally rotated 10 degrees counterclockwise and shifted 12 pixels left. The header paint and both original brand elements retain their positions.
