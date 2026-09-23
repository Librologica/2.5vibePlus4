"""xplus4 native captures. Monitor instrumentation adds no guest instructions."""
import argparse,json,subprocess,os,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
VICE=Path(os.environ.get('VICE_XPLUS4') or shutil.which('xplus4') or shutil.which('xplus4.exe') or 'xplus4')
PHASES=('render_frame_begin','render_frame_end','presentation_done','fps_frame_done','body_mode_store','bottom_pointer_store')
def run(build,standard='pal',cycles=12000000,tag='probe',frames=(3,4),extra=()):
    build=Path(build).resolve();out=build/tag;out.mkdir();native=build/'native'
    lines=[f'logname "{out.as_posix()}/trace.log"','log on','disable 1','sidefx off',f'load_labels "{native.as_posix()}/engine.labels"']
    lines+=['trace exec .'+n for n in PHASES]
    for i,frame in enumerate(frames,2+len(PHASES)):
        stem=f'frame-{frame:03d}'
        playback=[f'dump "{out.as_posix()}/{stem}.vsf"','bank ram',
                  f'bsave "{out.as_posix()}/{stem}-ram.bin" 0 $0000 $ffff','bank cpu',
                  f'bsave "{out.as_posix()}/{stem}-ted.bin" 0 $ff00 $ff1f','x']
        (out/(stem+'.mon')).write_text('\n'.join(playback)+'\n')
        lines += [f'break exec .presentation_done if (@ram:$0012 == ${frame&255:02x}) && (@ram:$0013 == ${frame>>8:02x})',
                  f'command {i} "playback \\"{out.as_posix()}/{stem}.mon\\""']
    lines+=list(extra)+['x'];(out/'run.mon').write_text('\n'.join(lines)+'\n')
    cmd=[str(VICE),'-default','+confirmonexit','-console','-warp','-model','plus4','-'+standard,'-TEDfilter','0',
         '-autostartprgmode','1','-initbreak','0x100d','-moncommands',str(out/'run.mon'),'-limitcycles',str(cycles),
         '-exitscreenshot',str(out/'ted.png'),str(native/'2.5VibePlus4.prg')]
    startup=None
    if os.name=='nt':
        startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
    p=subprocess.run(cmd,capture_output=True,timeout=240,startupinfo=startup)
    (out/'console.log').write_bytes(p.stdout+p.stderr);(out/'run.json').write_text(json.dumps(dict(command=cmd,returncode=p.returncode),indent=2))
    assert (out/'trace.log').exists() and all((out/f'frame-{f:03d}-ram.bin').exists() for f in frames),'Incomplete VICE capture; see console.log'
    print(out,p.returncode,flush=True);return out
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('build');p.add_argument('--standard',default='pal');p.add_argument('--tag',default='probe');p.add_argument('--cycles',type=int,default=12000000)
    a=p.parse_args();run(a.build,a.standard,a.cycles,a.tag)
