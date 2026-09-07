import argparse,json,subprocess,random,hashlib
from evidence import ROOT,environment,save,stats,require_gate
VERSIONS=json.loads((ROOT/'manifests/versions.json').read_text())

def run(version,mode):
    binary=ROOT/'build'/VERSIONS[version]
    p=subprocess.run([str(binary),mode],text=True,capture_output=True,timeout=300)
    records=[json.loads(line) for line in p.stdout.splitlines() if line.startswith('{')]
    return {'version':version,'revision':VERSIONS[version],'binary_sha256':hashlib.sha256(binary.read_bytes()).hexdigest(),
            'returncode':p.returncode,'stderr':p.stderr,'records':records}

def check():
    baseline=run('base','check');fixed=run('fixed','check')
    if baseline['returncode']!=2 or not any(not r['correct'] for r in baseline['records']):raise AssertionError('bad revision did not reproduce known defect')
    if fixed['returncode']!=0 or not fixed['records'] or not all(r['correct'] and r['guards'] for r in fixed['records']):
        raise AssertionError('patched revision failed')
    if len(baseline['records'])!=len(fixed['records']):raise AssertionError('version matrix differs')
    unsigned=[r for r in baseline['records'] if not r['signed']]
    if not unsigned or not all(r['correct'] for r in unsigned):raise AssertionError('baseline unsigned controls failed')
    oracle=subprocess.run([str(ROOT/'build/oracle_test')],text=True,capture_output=True,check=True)
    return {'status':'passed','environment':environment(),'versions':[baseline,fixed],'cpu':json.loads(oracle.stdout),
            'meaning':'known upstream failure reproduced; existing upstream patch independently passed this matrix'}

def benchmark(gate):
    checked=require_gate(gate);rows=[];rng=random.Random(1729);order=[]
    binaries={r['version']:r['binary_sha256'] for r in checked['versions']}
    for iteration in range(7):
        keys=['base','fixed'];rng.shuffle(keys);order.append(keys)
        for version in keys:
            result=run(version,'bench');result['round']=iteration
            if result['returncode']!=0 or any(not r['correct'] for r in result['records']):raise AssertionError('invalid performance input')
            if result['binary_sha256']!=binaries[version]:raise AssertionError('binary changed after correctness gate')
            for r in result['records']:r['statistics']=stats(r['raw_ms'])
            rows.append(result)
    return {'status':'measured','environment':environment(),'order':order,'seed':1729,'results':rows,
            'scope':'1M samples, resident allocations, 31 event samples x 20 calls; correctness checked before timed region'}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('phase',choices=['check','bench']);p.add_argument('--output',required=True);p.add_argument('--gate');a=p.parse_args()
    try:save(a.output,check() if a.phase=='check' else benchmark(a.gate))
    except Exception as exc:
        save(a.output,{'status':'failed','environment':environment(),'error':repr(exc)});raise
