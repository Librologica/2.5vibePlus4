"""Native 2.5D platform adapter; no polygonal renderer."""
import argparse, hashlib, json, os, re, shutil, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.dont_write_bytecode=True
sys.path.insert(0,str(ROOT/'src'))
from mode8.build import build as reference_build, labels, replace
from kernels import apply
from ui_font import update_font
TASS=Path(os.environ.get('TASS64_EXE') or shutil.which('64tass') or shutil.which('64tass.exe') or '64tass')
EXPECTED={'auto':'0F3D2BECB760564C82781FE3BDD1FBADB1EE75198D2CE608F98B6DB734BB545A',
          'interactive':'5E1E552858946A8099A31FD9D79010352D54163A6EFDDD4CC7F66E3FD7833532'}
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest().upper()
def assemble(dest,name):
    cmd=[str(TASS),'-a','-B','--m6502',f'--labels={name}.labels','--vice-labels-numeric',f'--list={name}.listing','-o',f'{name}.prg',f'{name}.asm']
    p=subprocess.run(cmd,cwd=dest,capture_output=True)
    (dest/f'{name}.assembler.log').write_bytes(p.stdout+p.stderr)
    if p.returncode:raise RuntimeError((p.stdout+p.stderr).decode(errors='replace'))
def read_labels(p):return {l.split()[2][1:]:int(l.split()[1],16) for l in Path(p).read_text().splitlines()}
def build(out,run='auto',kernels='combined',scene=None):
    out=Path(out).resolve()
    if out.is_relative_to(ROOT) or out.exists():raise ValueError('OUTPUT_DIRECTORY: use a new directory outside SDK')
    os.environ['TASS64_EXE']=str(TASS)
    # Keep the original expected hashes and reproduce them before the new map.
    scene=Path(scene).resolve() if scene else ROOT/'examples/demo2-optimized.json'
    base=out/'reference';ref=reference_build(scene,base,run)
    assert ref['contract']['backend']=='mono-portals' and not ref['contract']['automaticFallback']
    lab=labels(base);s=(base/'3Dvibe64.asm').read_text();dest=out/'native';dest.mkdir()
    s=re.sub(r'start:\n.*?(?=init_video_standard:)',lambda m:f'start:\n jmp native_init\n .fill ${lab["init_video_standard"]:04x}-*,0\n',s,count=1,flags=re.S)
    detect='''init_video_standard:
 lda $ff07
 and #$40
 sta ted_standard_bit
 beq ted_pal
 lda #1
 sta video_standard
 lda #60
 sta video_hz
 rts
ted_pal:
 lda #0
 sta video_standard
 lda #50
 sta video_hz
 rts
'''
    s=re.sub(r'init_video_standard:\n.*?(?=consume_video_ticks:)',lambda m:detect+f' .fill ${lab["consume_video_ticks"]:04x}-*,0\n',s,count=1,flags=re.S)
    s=re.sub(r'irq:\n.*?nmi:\n rti\n',lambda m:(ROOT/'src/native/irq.asm').read_text()+f'\n .fill ${lab["nmi"]+1:04x}-*,0\n',s,count=1,flags=re.S)
    # The original clear crosses permanent Plus/4 I/O. Keep identical length.
    for a in ('fcc0','fdc0','fec0'):
        s=s.replace(' sta $'+a+',x',' nop\n nop\n nop')
    # Clear the first addressable cells of high row 23. The TED bottom split
    # redirects the remaining margin to the low bitmap, whose data are zero.
    native=(ROOT/'src/native/init.asm').read_text().replace(' jsr vp_clear_frame\n',' jsr vp_clear_frame\n ldx #63\n lda #0\nted_clear_safe_tail:\n sta $fcc0,x\n dex\n bpl ted_clear_safe_tail\n')
    if run=='interactive':
        start=s.index('input_normal:\n');end=s.index('collision_check:',start)
        s=s[:start]+f'input_normal:\n jmp ted_read_controls\n .fill ${lab["collision_check"]:04x}-*,0\n\n'+s[end:]
    s,extra=apply(s,kernels,lab)
    (dest/'native.asm').write_text(native+'\n'+extra)
    assert s.count(' .fill 2449,0')==1
    s=s.replace(' .fill 2449,0',' .include "native.asm"\n native_end:\n .cerror *>$b991,"native budget"\n .fill $b991-*,0')
    text=['2.5VIBEPLUS4','FPS:00','AUTOMATIC TOUR' if run=='auto' else 'W/S MOVE A/D TURN - JOYSTICK PORT 2']
    s=replace(s,'ui_text',''.join(x.ljust(40) for x in text).encode('ascii'))
    (dest/'font.bin').write_bytes(update_font((base/'font.bin').read_bytes()))
    shutil.copyfile(base/'map.bin',dest/'map.bin')
    (dest/'engine.asm').write_text(s)
    assemble(dest,'engine');el=read_labels(dest/'engine.labels')
    for n in ('code_end','compose_screen','simulation_tick','latch_pose','raycast_layers','select_strips'):
        assert el[n]==lab[n],n
    engine=(dest/'engine.prg').read_bytes();assert engine[:2]==b'\x01\x08'
    (dest/'payload.bin').write_bytes(engine[2:])
    (dest/'2.5VibePlus4.asm').write_text((ROOT/'src/native/bootstrap.asm').read_text().replace('@PAYLOAD_BYTES@',str(len(engine)-2)))
    assemble(dest,'2.5VibePlus4')
    report=dict(project='2.5vibePlus4',run=run,kernels=kernels,family='apertures',sceneSHA256=sha(scene),owners=ref['owners'],referencePrgSHA256=ref['prgSHA256'],
        prgSHA256=sha(dest/'2.5VibePlus4.prg'),prgBytes=(dest/'2.5VibePlus4.prg').stat().st_size,
        nativeCodeBytes=el['native_end']-el['native_init'],nativeFree=0xb991-el['native_end'],
        viewport=[128,144],bitmapBuffers=[0x6000,0xe000],attributes=0xd800,colorMatrix=0xdc00,
        font=0x5800,fastClock=True,audio=False)
    (out/'build.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2));return report
