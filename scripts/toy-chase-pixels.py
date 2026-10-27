"""Observe toy-game controls from a rendered screenshot, without game-state access."""
import json
import sys
from PIL import Image

im = Image.open(sys.argv[1]).convert('RGB')
left, top, right, bottom = json.loads(sys.argv[2])
mode = sys.argv[3]
scale = (right - left) / 360

def regions(predicate):
    remaining = set()
    for y in range(top + 3, bottom - 3, 2):
        for x in range(left + 3, right - 3, 2):
            if predicate(*im.getpixel((x, y))):
                remaining.add((x, y))
    found = []
    while remaining:
        pending = [remaining.pop()]
        points = []
        while pending:
            p = pending.pop()
            points.append(p)
            x, y = p
            for q in [(x-2, y), (x+2, y), (x, y-2), (x, y+2)]:
                if q in remaining:
                    remaining.remove(q)
                    pending.append(q)
        if len(points) >= 12:
            xs, ys = zip(*points)
            found.append({'x': (min(xs)+max(xs))/2, 'y': (min(ys)+max(ys))/2,
                          'w': max(xs)-min(xs), 'h': max(ys)-min(ys), 'pixels': len(points)})
    return found

if mode == 'blackhole':
    rings = regions(lambda r, g, b: g > 105 and g > r+22 and g > b+20)
    rings = [p for p in rings if 8*scale < max(p['w'], p['h']) < 160*scale]
    holes = regions(lambda r, g, b: max(r, g, b) < 35)
    if not holes:
        raise RuntimeError('Rendered hole absent')
    print(json.dumps({'hole': max(holes, key=lambda p: p['pixels']), 'rings': rings}))
else:
    y = round(top + 390*scale)
    road = []
    car = []
    for x in range(left+3, right-3):
        r, g, b = im.getpixel((x, y))
        if b > r+5 and abs(b-g) < 25 and r < 150:
            road.append(x)
    for yy in range(round(y-29*scale), round(y+29*scale), 2):
        for x in range(left+3, right-3, 2):
            r, g, b = im.getpixel((x, yy))
            if r > 155 and r > g+45 and r > b+30:
                car.append((x, yy))
    if not road or not car:
        raise RuntimeError('Rendered road or toy car absent')
    xs, ys = zip(*car)
    upper = [x for x, yy in car if yy < y-8*scale]
    lower = [x for x, yy in car if yy > y+8*scale]
    direction = 1 if sum(upper)/len(upper) > sum(lower)/len(lower) else -1
    print(json.dumps({'center': (min(road)+max(road))/2, 'car': (min(xs)+max(xs))/2,
                      'direction': direction, 'scale': scale}))
