"""Independent C64 oracle compared with native Plus/4 RAM and TED state."""
import json,sys
from pathlib import Path
from functools import lru_cache
ROOT=Path(__file__).resolve().parents[1];sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT));sys.path.insert(0,str(ROOT/'src'))
from native_builder import read_labels
from mode8.reference import adapter
from mode8.build import load
from mode8.navigation import simulate
@lru_cache(maxsize=8)
def setup(build):
    d=load(Path(build)/'reference/scene.json');c,oracle,meta=adapter(d)
    return d,oracle,simulate(d['scene'],d['navigation'],backend=c['backend'])[0]
def check(build,out,frame,injected=False):
    build=Path(build);out=Path(out);r=(out/f'frame-{frame:03d}-ram.bin').read_bytes()
    ted=(out/f'frame-{frame:03d}-ted.bin').read_bytes();assert len(r)==65536 and len(ted)==32
    cfg=load(build/'build.json');lab=read_labels(build/'native/engine.labels')
    w=lambda a:int.from_bytes(r[a:a+2],'little')
    pose=tuple(w(a) for a in (38,40,42));d,oracle,poses=setup(build);expected=oracle(pose)[0]
    display=r[7];actual=r[0x63c0+display*32768:0x7f40+display*32768]
    # 20 complete rows 3..22 include all active pixels plus top/side margins.
    diff=sum(x!=y for x,y in zip(actual[:6400],expected[:6400]));assert diff==0,('bitmap',frame,pose,diff)
    # Row 23/24 are always fetched from the low bitmap, not from Plus/4 I/O.
    assert r[0x7cc0:0x7f40]==bytes(640),'low bottom margin'
    assert expected[6400:]==bytes(640),'oracle bottom margin'
    tick=w(20);pt=w(lab['frame_pose_tick'])
    if not injected:
        assert pose==tuple((poses[pt] if cfg['run']=='auto' else d['scene']['initial'])[:3]),('latched pose',frame,pt,pose)
        camera=tuple(w(a) for a in (32,34,36))
        assert camera==tuple((poses[tick] if cfg['run']=='auto' else d['scene']['initial'])[:3]),('camera',frame,tick,camera)
    assert pt<=tick and r[17]==0 and w(18)==frame
    assert display==frame%2 and r[6]==display^1 and r[8]==0,'double buffer order'
    assert r[0x5800:0x6000]==(build/'native/font.bin').read_bytes(),'font'
    assert r[0xd800:0xd878]==bytes([0x71])*120
    assert r[0xd878:0xdbe8]==bytes([0x42])*880
    assert r[0xdc78:0xdfe8]==bytes([0x98])*880
    assert r[0xdbe8:0xdc00]==r[0xdfe8:0xe000]==bytes([0xa5])*24
    engine=(build/'native/engine.prg').read_bytes()[2:];ui=engine[lab['ui_text']-0x801:lab['ui_text']-0x801+120]
    assert all(r[0xdc00+i]==v for i,v in enumerate(ui) if i not in (44,45))
    assert r[0xdc2c:0xdc2e]==f'{r[16]:02d}'.encode(),'FPS digits'
    assert ted[0x13]&0xfe==0x58,'font/fastclock'
    assert ted[0x14]&0xf8==0xd8,'matrix base'
    assert ted[0x15]&127==0 and ted[0x16]&127==0x67 and ted[0x19]&127==0
    assert ted[0x13]&1==0,'RAM mapping'
    result=dict(frame=frame,pose=pose,poseTick=pt,tick=tick,bitmapDifferentBytes=0,logicalPixelDifferences=0,
                display=display,attributes=True,font=True,UI=True,bufferOrder=True)
    (out/f'frame-{frame:03d}-check.json').write_text(json.dumps(result,indent=2)+'\n');return result
if __name__=='__main__':print(check(Path(sys.argv[1]),Path(sys.argv[2]),int(sys.argv[3])))
