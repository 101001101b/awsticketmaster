# Experiments — Plan de validación

## A) Calibración de C (capacidad por worker)
```bash
python run_experiment.py --type calibration --workers 1 --rates 10,20,50,100,200
```

## B) Throughput vs workers (speedup)
```bash
python run_experiment.py --type speedup --workers 1,2,4,8,16 --rate 500
```

## C) Stress / saturación
```bash
python run_experiment.py --type stress --workers 4 --max-rate 1000
```

## D) Elasticidad (Z(t) completo)
```bash
python run_experiment.py --type elasticity --workers-min 1 --workers-max 20
```

## E) Contención: uniforme vs hotspot 80/5
```bash
# Uniforme
python run_experiment.py --type contention --hotspot-pct 100

# Hotspot 80/5
python run_experiment.py --type contention --hotspot-pct 5 --hotspot-traffic 80
```
