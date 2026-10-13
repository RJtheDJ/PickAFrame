"""Cut a tileable moulding strip out of a front-on photo of a frame.

The app renders "photo mouldings" (ornate gold, carved frames, ...) by tiling a
strip along each rail. A strip image has:
  * its OUTER edge along the top row and its INNER (artwork-side) edge along
    the bottom row, so the image height is the moulding's face width;
  * the moulding running left to right, so it can repeat horizontally.

Usage:
  python tools/make_moulding_strip.py PHOTO OUT.jpg --rail left --box X0 Y0 X1 Y1

  --rail  which side of the frame the box is on (top/bottom/left/right). It is
          used to rotate the crop so the outer edge ends up on top.
  --box   pixel box of a straight stretch of that rail, outer edge to inner
          edge, clear of the mitred corners.

The script finds the ornament's repeat period by autocorrelation and trims the
strip to a whole number of periods, so `TileMode.repeated` has no visible seam.
Pass --no-period to keep the full crop (then use mirror tiling in the app).

It also writes OUT_nor.jpg, a normal map estimated from the photo's shading,
which lets the app relight the carving when the light moves. Use
--normal-strength to make the relief deeper or shallower.
"""

import argparse

import numpy as np
from PIL import Image

# Rotation (degrees, counter-clockwise as PIL uses) that puts each rail's outer
# edge on top.
ROTATE_OUTER_TO_TOP = {'top': 0, 'right': 90, 'bottom': 180, 'left': -90}


def find_period(strip: np.ndarray, min_period: int) -> int | None:
    """Repeat length in pixels along x, or None if nothing clearly repeats."""
    # Compare every row (not one averaged profile) so the ornament's shape
    # counts, after removing slow lighting changes along the rail.
    rows = strip.mean(axis=2)  # height x length brightness
    window = max(3, min_period * 2)
    kernel = np.ones(window) / window
    detail = np.array([r - np.convolve(r, kernel, mode='same') for r in rows])

    n = rows.shape[1]
    corr = np.zeros(n)
    for r in detail:
        r = r - r.mean()
        corr += np.correlate(r, r, mode='full')[n - 1:]
    if corr[0] == 0:
        return None
    corr /= corr[0]
    corr *= n / (n - np.arange(n))  # correct for the shrinking overlap

    search = corr[min_period:n // 2]
    if len(search) == 0:
        return None
    lag = int(np.argmax(search)) + min_period
    # Photos of real (cast or carved) ornament never match perfectly.
    return lag if corr[lag] > 0.12 else None


def flatten_lighting(strip: Image.Image) -> Image.Image:
    """Evens out brightness along the length (photo lighting falls off toward
    the frame's corners), keeping the across-the-face shading intact."""
    pixels = np.asarray(strip).astype(float)
    column_brightness = pixels.mean(axis=(0, 2))
    window = max(3, strip.height * 2)
    padded = np.pad(column_brightness, window, mode='reflect')
    trend = np.convolve(padded, np.ones(window) / window, mode='same')[window:-window]
    pixels *= (column_brightness.mean() / trend)[None, :, None]
    return Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8))


def normal_map(strip: Image.Image, strength: float) -> Image.Image:
    """Estimates surface normals from shading ("shape from shading"): in an
    evenly lit photo of gilded relief, raised parts are bright and recesses are
    dark, so brightness is used as height. Output follows the OpenGL
    convention (+y up), like the app's other normal maps."""
    gray = np.asarray(strip.convert('L')).astype(float) / 255.0
    # Soften JPEG noise and fine glints so only the carving's shape remains.
    kernel = np.array([1, 4, 6, 4, 1], dtype=float)
    kernel /= kernel.sum()
    height = np.apply_along_axis(lambda r: np.convolve(np.pad(r, 2, mode='wrap'), kernel, 'valid'), 1, gray)
    height = np.apply_along_axis(lambda c: np.convolve(np.pad(c, 2, mode='edge'), kernel, 'valid'), 0, height)

    # Wrap along the length so the map tiles like the strip; clamp across it.
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) / 2
    padded = np.pad(height, ((1, 1), (0, 0)), mode='edge')
    dy = (padded[2:] - padded[:-2]) / 2  # image rows run down

    nx = -dx * strength
    ny_up = dy * strength  # flip to +y up
    nz = np.ones_like(height)
    length = np.sqrt(nx * nx + ny_up * ny_up + nz * nz)
    rgb = np.stack([nx, ny_up, nz], axis=2) / length[..., None]
    return Image.fromarray(((rgb * 0.5 + 0.5) * 255).round().astype(np.uint8))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('photo')
    parser.add_argument('out')
    parser.add_argument('--rail', required=True, choices=ROTATE_OUTER_TO_TOP)
    parser.add_argument('--box', required=True, nargs=4, type=int, metavar=('X0', 'Y0', 'X1', 'Y1'))
    parser.add_argument('--no-period', action='store_true')
    parser.add_argument('--normal-strength', type=float, default=6.0)
    args = parser.parse_args()

    crop = Image.open(args.photo).convert('RGB').crop(tuple(args.box))
    strip = crop.rotate(ROTATE_OUTER_TO_TOP[args.rail], expand=True)
    strip = flatten_lighting(strip)
    pixels = np.asarray(strip).astype(float)

    if not args.no_period:
        # Ornaments repeat at least every half face width.
        period = find_period(pixels, min_period=max(8, strip.height // 2))
        if period:
            repeats = strip.width // period
            strip = strip.crop((0, 0, repeats * period, strip.height))
            print(f'period {period}px, keeping {repeats} repeats')
        else:
            print('no clear repeat found; use mirror tiling for this strip')

    strip.save(args.out, quality=90)
    print(f'wrote {args.out}: {strip.width}x{strip.height}')

    normal_path = args.out.rsplit('.', 1)[0] + '_nor.jpg'
    normal_map(strip, args.normal_strength).save(normal_path, quality=92)
    print(f'wrote {normal_path}')


if __name__ == '__main__':
    main()
