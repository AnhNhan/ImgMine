
import anhnhan.image.common {
    RGB,
    View,
    rgbFromInteger
}

import java.awt {
    Graphics2D,
    AlphaComposite,
    RenderingHints
}
import java.awt.image {
    BufferedImage
}
import java.io {
    File,
    InputStream
}
import java.net {
    URL
}

import javax.imageio {
    ImageIO
}

shared
class BufferedImageView(BufferedImage img)
        satisfies View<RGB>
{
    shared
    BufferedImage src = img;

    shared actual
    Integer height
            => src.height;

    shared actual
    Integer width
            => src.width;

    defines([Integer, Integer] key) => key[0] < width && key[1] < height;

    shared actual
    RGB? get([Integer, Integer] key)
            => defines(key) then rgbFromInteger(src.getRGB(key[0], key[1]));
}

shared
BufferedImageView resizeBufferedImageView(BufferedImageView src, Integer newW, Integer newH)
{
    value bimg = src.src;

    BufferedImage resizedImage = BufferedImage(newW, newH, BufferedImage.\iTYPE_INT_ARGB);
    Graphics2D g = resizedImage.createGraphics();
    g.drawImage(bimg, 0, 0, newW, newH, null);
    g.dispose();
    g.composite = AlphaComposite.\iSrc;

    g.setRenderingHint(RenderingHints.\iKEY_INTERPOLATION, RenderingHints.\iVALUE_INTERPOLATION_BILINEAR);
    g.setRenderingHint(RenderingHints.\iKEY_RENDERING, RenderingHints.\iVALUE_RENDER_QUALITY);
    g.setRenderingHint(RenderingHints.\iKEY_ANTIALIASING, RenderingHints.\iVALUE_ANTIALIAS_ON);

    return BufferedImageView(resizedImage);
}

shared
BufferedImageView loadImage(File|InputStream|URL|String input)
{
    BufferedImage img;
    switch (input)
    case (is String)
    {
        img = ImageIO.read(File(input));
    }
    case (is File)
    {
        img = ImageIO.read(input);
    }
    case (is InputStream)
    {
        img = ImageIO.read(input);
    }
    case (is URL)
    {
        img = ImageIO.read(input);
    }

    return BufferedImageView(img);
}
