"""Timing uses TED master-clock ticks, never host execution time."""
import json,re,statistics,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT))
sys.path.insert(0,str(ROOT/'src'))
from native_builder import read_labels
HZ={'pal':1773447,'ntsc':1789772}
def stats(v):
    a=sorted(v);assert a
    return dict(n=len(a),mean=statistics.mean(a),median=statistics.median(a),p95=a[int(.95*(len(a)-1))],minimum=min(a),maximum=max(a))
def analyze(build,out,standard,seconds=20):
    build=Path(build);out=Path(out);lab=read_labels(build/'native/engine.labels');events=[];raster=None;switches=[]
    names=('render_frame_begin','render_frame_end','presentation_done','fps_frame_done')
    inv={lab[n]:n for n in names}
    for line in (out/'trace.log').read_text(errors='replace').splitlines():
        m=re.search(r'\)\s+(\d+)/\$[0-9a-f]+,\s+(\d+)/\$',line)
        if m:raster=(int(m[1]),int(m[2]))
        m=re.search(r'\.C:([0-9a-f]{4}).*\s(\d+)\s*$',line)
        if not m:continue
        pc,t=int(m[1],16),int(m[2])
        if pc in (lab['body_mode_store'],lab['bottom_pointer_store']):switches.append(dict(pc=pc,t=t,raster=raster))
        if pc in inv and (not events or events[-1]!=(inv[pc],t)):events.append((inv[pc],t))
    for e in switches:
        row,col=e['raster']
        if e['pc']==lab['body_mode_store']:assert 28<=row<=32,e
        else:
            # This event is STA entry, not its bus write. TED can stall a STA
            # entered at cycle 3 through the badline until cycle 97. See the
            # separate actual-store trace test; never accept line-188 writes.
            assert row==187 and (col<=3 or 87<=col<=105),e
    pub=[t for n,t in events if n=='fps_frame_done'];lo=pub[0]+2*HZ[standard];hi=lo+seconds*HZ[standard]
    assert pub[-1]>hi,'Incomplete measurement window'
    frames=[];cur={}
    for n,t in events:
        if n=='render_frame_begin':cur={}
        cur[n]=t
        if n=='presentation_done' and all(k in cur for k in names):frames.append(cur.copy())
    used=[f for f in frames if lo<=f['fps_frame_done']<hi]
    intervals=[b-a for a,b in zip(pub,pub[1:]) if lo<=b<hi]
    result=dict(standard=standard,Hz=HZ[standard],windowSeconds=seconds,warmupSeconds=2,
        images=sum(lo<=t<hi for t in pub),fps=sum(lo<=t<hi for t in pub)/seconds,
        intervalTEDClocks=stats(intervals),intervalMs=stats([v*1000/HZ[standard] for v in intervals]),
        renderIncludingIRQ=stats([f['render_frame_end']-f['render_frame_begin'] for f in used]),
        readyToPublication=stats([f['fps_frame_done']-f['render_frame_end'] for f in used]),
        poseToPublicationMs=stats([(f['fps_frame_done']-f['render_frame_begin'])*1000/HZ[standard] for f in used]),
        windowStart=lo,windowEnd=hi,rasterSwitchChecks=len(switches),UI=True,audio=False,
        measurement='TED master clock, includes display contention, interrupts and presentation; warp is host acceleration only')
    (out/'timing.json').write_text(json.dumps(result,indent=2)+'\n');(out/'frame-events.json').write_text(json.dumps(frames,indent=2)+'\n')
    print(build.name,standard,result['fps'],result['intervalMs'],flush=True);return result
if __name__=='__main__':analyze(Path(sys.argv[1]),Path(sys.argv[2]),sys.argv[3])
