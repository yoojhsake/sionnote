# -*- coding: utf-8 -*-
"""캡처 이미지에서 비공개 영역을 가려서 assets/images/YYYY/MM/ 에 저장한다.
사용법 (저장소 루트에서 실행, Python + Pillow 필요: pip install pillow)
  1) 좌표 확인용 격자 이미지:   python tools/blur.py raw/캡처.png --grid
  2) 가리기(모자이크):          python tools/blur.py raw/캡처.png --box 600,10,800,50 --box 20,300,400,340
  3) 검은 칠로 가리기:          python tools/blur.py raw/캡처.png --box 600,10,800,50 --mode solid
좌표는 이미지 픽셀 기준 x0,y0,x1,y1. 원본은 raw/ 폴더(.gitignore 처리)에 두고 가린 사본만 올린다.
"""
import argparse, os, datetime
from PIL import Image, ImageDraw

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src'); ap.add_argument('--box', action='append', default=[])
    ap.add_argument('--mode', choices=['mosaic', 'solid'], default='mosaic')
    ap.add_argument('--grid', action='store_true'); ap.add_argument('--name')
    a = ap.parse_args()
    im = Image.open(a.src).convert('RGB'); w, h = im.size
    if a.grid:
        d = ImageDraw.Draw(im)
        for x in range(0, w, 100): d.line([(x, 0), (x, h)], fill=(0, 120, 255)); d.text((x + 2, 2), str(x), fill=(0, 0, 255))
        for y in range(0, h, 100): d.line([(0, y), (w, y)], fill=(0, 120, 255)); d.text((2, y + 2), str(y), fill=(0, 0, 255))
        out = os.path.splitext(a.src)[0] + '_grid.png'; im.save(out); print('격자 이미지:', out); return
    if not a.box: raise SystemExit('--box x0,y0,x1,y1 를 하나 이상 지정하세요')
    for b in a.box:
        x0, y0, x1, y1 = [int(v) for v in b.split(',')]
        x0, y0, x1, y1 = max(0, x0), max(0, y0), min(w, x1), min(h, y1)
        if a.mode == 'solid':
            ImageDraw.Draw(im).rectangle([x0, y0, x1, y1], fill=(0, 0, 0))
        else:  # 되돌릴 수 없도록 큰 블록 모자이크
            reg = im.crop((x0, y0, x1, y1)); bw = max(1, (x1 - x0) // 12); bh = max(1, (y1 - y0) // 4)
            reg = reg.resize((max(1, (x1 - x0) // bw), max(1, (y1 - y0) // bh)), Image.BILINEAR).resize((x1 - x0, y1 - y0), Image.NEAREST)
            im.paste(reg, (x0, y0))
    t = datetime.date.today(); folder = os.path.join('assets', 'images', '%d' % t.year, '%02d' % t.month)
    os.makedirs(folder, exist_ok=True)
    name = a.name or os.path.splitext(os.path.basename(a.src))[0] + '.png'
    out = os.path.join(folder, name); im.save(out)
    print('저장:', out); print('글에 넣기: ![설명]({{ "/%s" | relative_url }})' % out.replace(os.sep, '/'))

if __name__ == '__main__': main()
