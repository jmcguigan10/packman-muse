# g4PSI sample macro command reference

This directory contains sample g4PSI macros for MUSE-style simulation work:

| File | Purpose | Typical command |
|---|---|---|
| `sample.mac` | Original local full-detector sample for a 160 MeV `mu+` beam. Useful for smoke tests, relay cooking checks, and acceptance/hazard-model development. | `g4PSI sample.mac` |
| `full-sample.mac` | Combined sample with the fuller local detector/testplane setup plus Matt's run-22308 positron beam, detector thresholds, alignments, triggers, and LH2 target settings. | `g4PSI --rad2 full-sample.mac` |
| `matt-sample.mac` | Direct reference copy of Matt's run-22308 positron macro. Use this when you want to compare against the exact settings from the email. | `g4PSI --rad2 matt-sample.mac` |

`sample.mac` is written for a 160 MeV `mu+` beam. `full-sample.mac` and
`matt-sample.mac` are written for the run-22308-style `e+` simulation that
Matt described. All three are intended to produce g4PSI ROOT output suitable
for downstream relay cooking, cross-section checks, and acceptance or
hazard-model studies.

The macro is executed sequentially. The important ordering rule is:

```text
define detector geometry and triggers
initialize Geant4
define beam/gun and output
run events
```

Most detector commands must appear before `/run/initialize`. The beam,
ROOT output file, and `/run/beamOn` commands appear after initialization.

## Running the macros

Plain non-radiative run with the local `mu+` sample:

```bash
g4PSI sample.mac
```

Radiative run using the local forced RadGen sample:

```bash
g4PSI --rad3 sample.mac
```

Matt-style biased radiative positron run:

```bash
g4PSI --rad2 full-sample.mac
```

Exact Matt reference macro:

```bash
g4PSI --rad2 matt-sample.mac
```

The `--rad`, `--rad1`, `--rad2`, and `--rad3` arguments are command-line
arguments to `g4PSI`. They are not macro commands, but they change how the
macro's optional `/g4PSI/radgen/...` settings are used.

## High-level data products

The macro writes a g4PSI ROOT file using:

```text
/g4PSI/run/rootfile runs/manual_muplus_160MeV/run001.root
```

That ROOT file contains the g4PSI event tree, usually named `T`, with:

| Data | Why it matters |
|---|---|
| `EventInfo` | Run/event metadata and `EventInfo.weight`, which is required for biased RadGen samples. |
| `GeneratorEvent` | Boolean indicating whether the event was produced by the RadGen generator path. |
| Beam branches | Beam particle, momentum, direction, time, and origin information. |
| Detector hit branches | Raw simulated hits for detectors enabled in the macro. |
| Sensitive detector records | Needed by downstream MUSE cooker recipes such as BH, SPS, GEM, STT, VETO, TCPV, PbGlass/CAL, vertexing, and pathlength. |

For acceptance or termination-hazard modeling, the most important rule is:

```text
Always carry EventInfo.weight into every exported candidate or stage table.
```

This is especially important for `--rad2`, `--rad3`, or any RadGen angular
bias settings.

## Command-line radiative modes

These are selected outside the macro:

```bash
g4PSI --rad3 sample.mac
```

| Mode | Internal enhancement value | What it does | What is written to the ROOT tree |
|---|---:|---|---|
| no `--rad...` argument | none | Normal Geant4 transport. No RadGen radiative scattering process is enabled. | Normal triggered events. |
| `--rad` | `0` | Enables the RadGen scattering physics process with no enhancement. | In this checkout, the fill rule writes triggered non-generator events for enhancement `0`, so this is usually not the useful choice for collecting RadGen events. |
| `--rad1` | `1` | Enables the RadGen process without the large cross-section boost used by `rad2`. | Triggered events are written, including generator and non-generator events. |
| `--rad2` | `2` | Enables the RadGen process and boosts the RadGen scattering probability in LH2 by a factor of `1000`. | Triggered generator events are written. Non-generator primaries are stopped when they reach BM. Event weights compensate the bias. |
| `--rad3` | `3` | Forces a RadGen scatter along the primary track through the target instead of waiting for the normal scattering probability. | Triggered forced-generator events are written. Event weights include the RadGen weight and target path length factor. |

Practical recommendation for the hazard-model workflow:

| Goal | Recommended mode | Reason |
|---|---|---|
| High-statistics radiative training sample | `--rad3` | Efficiently generates target radiative scatters across the requested angular phase space. |
| Cross-check with less forcing | `--rad1` | More natural generator behavior, but lower radiative statistics. |
| Biased but process-driven radiative sample | `--rad2` | Useful if you want an enhanced interaction probability rather than forced target scattering. |
| Ordinary detector acceptance debugging | no `--rad...` argument | Avoids radiative-generator complications. |

## RadGen macro controls

These commands only matter when the executable is launched with `--rad`,
`--rad1`, `--rad2`, or `--rad3`, or when `/gun/mode radgen` is used. They do
not select the radiative mode by themselves.

```mac
/g4PSI/radgen/theta_min 20 deg
/g4PSI/radgen/theta_max 65 deg
/g4PSI/radgen/phi_range 90 deg
/g4PSI/radgen/theta_distribution 2
/g4PSI/radgen/soft_fraction 0.5
```

| Command | Meaning | Example value | Effect |
|---|---|---:|---|
| `/g4PSI/radgen/theta_min` | Minimum scattered-lepton polar angle. | `20 deg` | RadGen does not generate radiative scattered leptons below this angle. |
| `/g4PSI/radgen/theta_max` | Maximum scattered-lepton polar angle. | `65 deg` | RadGen does not generate radiative scattered leptons above this angle. |
| `/g4PSI/radgen/phi_range` | Azimuthal half-range around the two spectrometer directions. | `90 deg` | `90 deg` covers the full azimuth because the code samples around `0 +/- range` and `180 +/- range`. |
| `/g4PSI/radgen/theta_distribution` | Proposal distribution used to sample theta. | `2` | Changes statistics across theta. It does not by itself define the physical cross section. |
| `/g4PSI/radgen/soft_fraction` | Mixture parameter for radiative energy-loss sampling. | `0.5` | Controls how often the generator draws from the soft-enhanced sampling branch. Event weights compensate it. |

### Theta range

The theta range is the generated scattered-lepton polar-angle range relative
to the incoming beam direction.

```text
/g4PSI/radgen/theta_min 20 deg
/g4PSI/radgen/theta_max 65 deg
```

This means RadGen only generates candidates in:

```text
20 deg <= theta <= 65 deg
```

For model training, this becomes part of the training domain. If the sample
only generates `20-65 deg`, the trained model should not be interpreted as a
validated model outside `20-65 deg` unless additional samples cover those
angles.

### Phi range

The phi range is an azimuthal half-width. The implementation samples around
two directions:

```text
phi = 0 +/- phi_range
phi = 180 deg +/- phi_range
```

So:

| `phi_range` | Meaning |
|---:|---|
| `90 deg` | Full azimuthal coverage. |
| `45 deg` | Two broad wedges centered around left/right spectrometer directions. |
| `30 deg` | Two narrower wedges centered around left/right spectrometer directions. |

Use `90 deg` when you want full coverage and want later detector/reconstruction
cuts to determine acceptance. Use a smaller value only when you intentionally
want to concentrate statistics near the spectrometer azimuths.

### Theta distribution codes

| Code | Name | Sampling behavior | When to use |
|---:|---|---|---|
| `0` | `flat_costheta` | Samples uniformly in `cos(theta)`. | Good for solid-angle-like sampling. |
| `1` | `rutherford` | Samples with a forward-peaked Rutherford-like proposal. | Good when you want more statistics near small scattering angles. |
| `2` | `flat_theta` | Samples uniformly in theta. | Good for acceptance or hazard studies where you want more even statistics per degree. |

These are proposal distributions. The event weights correct the sampling back
to the generator's physical weighting. Do not drop `EventInfo.weight`.

### Soft fraction

`/g4PSI/radgen/soft_fraction` is not a physical statement that some fraction
of events are physically soft photons. It is a sampling mixture parameter for
the radiative energy-loss variable.

With:

```text
/g4PSI/radgen/soft_fraction 0.5
```

about half the generated events are drawn from the soft-enhanced sampling
branch and half from the other branch. The generator then computes a
compensating weight.

For muon beams in this checkout, if `soft_fraction` is not explicitly set, the
code defaults to `0.0` for `mu+` and `mu-`. Uncommenting `soft_fraction 0.5`
overrides that behavior. That can be useful for studying the soft-radiation
tail, but it also makes carrying weights even more important.

## Macro command inventory

The rest of this document explains each command used in `sample.mac`.

## Control and logging

| Command | Meaning |
|---|---|
| `/control/verbose 1` | Sets Geant4 UI/control verbosity. `1` gives basic command-processing output without very detailed debug output. |

Use higher verbosity only for debugging. Production jobs should keep this
modest because large batch runs can produce excessive logs.

## Detector component commands

Detector components are enabled with:

```text
/g4PSI/det/component <component-name> [option = value, ...]
```

Each component line turns on a geometry/detector object. Options after the
component name are passed to that detector's construction code. Options are
component-specific, so the same option name can mean slightly different things
depending on the detector.

Common options:

| Option | Meaning |
|---|---|
| `threshold = ...` | Minimum energy deposit required for the detector to count a hit. |
| `testplane = yes` or `testplane = 1` | Adds or enables test-plane style diagnostic output for that detector. Useful for geometry and acceptance studies. |
| `SD = yes` | Makes the volume sensitive so interactions or hits are recorded. |
| `type = ...` | Selects a detector geometry/configuration variant. |
| `length = ...` | Sets a detector length. |
| `state = open` | Puts a movable detector/beamline element in an open configuration. |
| `shift_h_*`, `shift_v_*`, `angle_*` | Alignment offsets and rotations. |
| `wire_file = ...` | Mapping file for straw-tube wire geometry or channel layout. |

### Beamline

```text
/g4PSI/det/component Beamline degrader = no, testplane = yes
```

| Part | Meaning |
|---|---|
| `Beamline` | Enables the upstream beamline geometry. |
| `degrader = no` | Does not include the degrader material in the beamline. A degrader would alter the beam energy and energy spread. |
| `testplane = yes` | Enables diagnostic test-plane information for checking beam transport and acceptance. |

For hazard modeling, this matters because the beamline defines the incoming
particle state before the target. It affects the truth denominator through the
beam phase space.

### Beam hodoscopes

```text
/g4PSI/det/component BHC testplane = 1
/g4PSI/det/component BHD threshold = 0.15 MeV, testplane = 1
```

| Component | Meaning | Important options |
|---|---|---|
| `BHC` | Beam hodoscope C. Upstream beam counter. | `testplane = 1` records/assists diagnostic beamline information. |
| `BHD` | Beam hodoscope D. Important for beam trigger and beam particle identification. | `threshold = 0.15 MeV` sets the hit threshold; `testplane = 1` enables diagnostic output. |

`BHD` is especially important because the sample trigger includes BHD, and the
cross-section pipeline uses BH information for PID-related acceptance.

### GEM trackers

```text
/g4PSI/det/component GEM0
/g4PSI/det/component GEM1
/g4PSI/det/component GEM2
/g4PSI/det/component GEM3
```

These enable the four GEM tracking stations. They are required for downstream
GEM hit processing and GEM track reconstruction.

| Component | Role |
|---|---|
| `GEM0` | First GEM tracking detector. |
| `GEM1` | Second GEM tracking detector. |
| `GEM2` | Third GEM tracking detector. |
| `GEM3` | Fourth GEM tracking detector. |

For a termination hazard model, these support stages such as:

```text
generated truth -> detector hit -> GEM hit reconstruction -> GEM track -> tracklet -> vertex
```

### Veto, chamber, target, and CHV

```text
/g4PSI/det/component VETO threshold = 4.0 MeV
/g4PSI/det/component ScatteringChamber_TypeTrapezoid SD = yes
/g4PSI/det/component CHV threshold = 0.45 MeV, type = 13, length = 200 mm
/g4PSI/det/component Target_TypeUMich ladder = LH2, SD = yes
```

| Component | Meaning | Important options |
|---|---|---|
| `VETO` | Enables the veto detector. | `threshold = 4.0 MeV` sets the energy-deposit threshold for veto hits. |
| `ScatteringChamber_TypeTrapezoid` | Enables the trapezoid scattering chamber geometry. | `SD = yes` records sensitive-detector information in the chamber volume. |
| `CHV` | Enables the CHV detector/volume with the selected configuration. | `threshold = 0.45 MeV`, `type = 13`, and `length = 200 mm` set hit and geometry choices. |
| `Target_TypeUMich` | Enables the UMich target ladder. | `ladder = LH2` selects the liquid-hydrogen target; `SD = yes` records sensitive target information. |

For acceptance modeling:

| Detector/volume | Hazard-model relevance |
|---|---|
| `VETO` | Supplies no-veto or veto-failure information. |
| `ScatteringChamber_TypeTrapezoid` | Adds realistic material and sensitive chamber information. |
| `CHV` | Adds chamber-veto related hit information where used downstream. |
| `Target_TypeUMich ladder = LH2` | Defines the physical scattering target and the denominator for target-scatter truth candidates. |

### Beam monitor

```text
/g4PSI/det/component BM state = open, shift_h_BMA = -11.31168 mm, shift_v_BMA = 1.09080 mm, angle_BMA = 0.03957 deg, testplane = yes
```

| Option | Meaning |
|---|---|
| `state = open` | Uses the open beam-monitor configuration. |
| `shift_h_BMA = -11.31168 mm` | Horizontal alignment shift for BMA. |
| `shift_v_BMA = 1.09080 mm` | Vertical alignment shift for BMA. |
| `angle_BMA = 0.03957 deg` | Angular alignment correction for BMA. |
| `testplane = yes` | Enables diagnostic output. |

The BM is part of the normal relay/cross-section pipeline. It is also useful
for checking whether the beam phase space and alignment are consistent across
runs.

### Calorimeter

```text
/g4PSI/det/component CAL n = 8, converter_thickness = 4 mm, converter_material = G4_AIR, air_gap = 0.1 cm, testplane = yes
```

| Option | Meaning |
|---|---|
| `n = 8` | Builds 8 calorimeter modules/channels in this configuration. |
| `converter_thickness = 4 mm` | Sets converter thickness. |
| `converter_material = G4_AIR` | Uses air as the converter material in this sample. |
| `air_gap = 0.1 cm` | Sets the air gap. |
| `testplane = yes` | Enables diagnostic output. |

This supports the calorimeter/PbGlass side of the pipeline. In the acceptance
logic we discussed, this is where a `pass calo` or `calo veto` stage can come
from, depending on the downstream recipe and cut definition.

### STT and SPS

```text
/g4PSI/det/component STTL testplane = yes, wire_file = XYZ_STTL_mapping.csv
/g4PSI/det/component STTR testplane = yes, wire_file = XYZ_STTR_mapping.csv
/g4PSI/det/component SPSLF threshold = 1.5 MeV
/g4PSI/det/component SPSRF threshold = 1.5 MeV
/g4PSI/det/component SPSLR threshold = 1.5 MeV
/g4PSI/det/component SPSRR threshold = 1.5 MeV
/g4PSI/det/component TestPlanes
```

| Component | Meaning | Important options |
|---|---|---|
| `STTL` | Left straw-tube tracker. | `wire_file = XYZ_STTL_mapping.csv` gives the wire/channel mapping. |
| `STTR` | Right straw-tube tracker. | `wire_file = XYZ_STTR_mapping.csv` gives the wire/channel mapping. |
| `SPSLF` | Left front scattered-particle scintillator. | `threshold = 1.5 MeV` sets hit threshold. |
| `SPSRF` | Right front scattered-particle scintillator. | `threshold = 1.5 MeV` sets hit threshold. |
| `SPSLR` | Left rear scattered-particle scintillator. | `threshold = 1.5 MeV` sets hit threshold. |
| `SPSRR` | Right rear scattered-particle scintillator. | `threshold = 1.5 MeV` sets hit threshold. |
| `TestPlanes` | Enables general diagnostic test planes. | No options in this sample. |

These are central to the acceptance chain:

| Stage | Relevant detector |
|---|---|
| `pass SPS side` | SPS left/right front/rear coincidences. |
| `pass LUT5` | SPS-side trigger logic in downstream analysis. |
| `tracklet` | STT and GEM-derived reconstruction. |
| `vertex` | Tracklet and tracking reconstruction. |
| `TOF` | Timing information from beam and scattered-particle detectors. |

## Detector parameters

These commands set global geometry/material parameters used by detector
construction.

```text
/g4PSI/det/kapton_thickness 120 um
/g4PSI/det/target_radius 30 mm
/g4PSI/det/pipe_distance 60 mm
/g4PSI/det/pipe_angle 25 deg
/g4PSI/det/entrance_window_thickness 120 um
/g4PSI/det/info info.txt
/g4PSI/det/setup standard2015
```

| Command | Meaning | Why it matters |
|---|---|---|
| `/g4PSI/det/kapton_thickness 120 um` | Sets Kapton material thickness used by relevant detector/window geometry. | Changes material budget and multiple scattering. |
| `/g4PSI/det/target_radius 30 mm` | Sets the target radius parameter. | Affects target geometry and generated/accepted target phase space. |
| `/g4PSI/det/pipe_distance 60 mm` | Sets the distance for the target/scattering pipe geometry. | Affects material/geometry around outgoing tracks. |
| `/g4PSI/det/pipe_angle 25 deg` | Sets the pipe angle. | Affects whether outgoing particles pass through pipe/aperture material. |
| `/g4PSI/det/entrance_window_thickness 120 um` | Sets entrance window material thickness where used. | Changes energy loss and scattering before/near the target. |
| `/g4PSI/det/info info.txt` | Requests detector/setup information output to `info.txt`. | Useful for run auditing. |
| `/g4PSI/det/setup standard2015` | Selects the named detector setup/configuration. | Defines the baseline MUSE geometry layout. |

For hazard modeling, these settings should be treated as part of the simulation
configuration. If you compare datasets, changes here can change acceptance in
ways that look like detector or reconstruction effects.

## Multiple-scattering setting

```text
/process/msc/ThetaLimit 5 deg
```

This sets the Geant4 multiple-scattering theta limit. In this code path, the
RadGen scattering model uses the multiple-scattering theta limit as the
boundary between small-angle Coulomb-style scattering and the larger-angle
generator treatment.

Practical meaning:

| Value | Effect |
|---|---|
| Smaller theta limit | More scatterings are treated as large-angle/single-scattering-like. |
| Larger theta limit | More angular changes remain in the multiple-scattering regime. |
| `5 deg` | Current relay-style convention used by this sample. |

Do not change this casually between production datasets. It can change the
truth-to-reconstruction acceptance surface.

## Trigger definitions

```text
/g4PSI/det/trigger SPSLF SPSLR BHD 1
/g4PSI/det/trigger SPSRF SPSRR BHD 1
/g4PSI/det/trigger BHD 1
```

Each trigger line defines one trigger branch. The branches are ORed together.
Within one line, the listed detectors are ANDed together.

The implementation also supports a leading `!` on a detector name to mean a
veto condition, although this sample does not use that syntax.

| Command | Meaning |
|---|---|
| `/g4PSI/det/trigger SPSLF SPSLR BHD 1` | Left-arm SPS front and rear counters plus BHD must hit. |
| `/g4PSI/det/trigger SPSRF SPSRR BHD 1` | Right-arm SPS front and rear counters plus BHD must hit. |
| `/g4PSI/det/trigger BHD 1` | BHD-only trigger branch. |

The trailing integer is a power-of-two prescale exponent. The code converts it
to:

```text
prescale_factor = 2 ^ trailing_integer
```

So the sample's trailing `1` means:

```text
prescale_factor = 2
```

An otherwise passing trigger branch is accepted with probability approximately:

```text
1 / prescale_factor
```

For `1`, that is about one half. A trailing `0` would accept every otherwise
passing trigger branch.

For hazard modeling, remember that the g4PSI ROOT tree may already be trigger
filtered. If the training denominator is supposed to include particles before
the g4PSI trigger filter, you need a separate truth export or a less restrictive
trigger/output strategy.

## Geant4 initialization

```text
/run/initialize
```

This initializes Geant4 after the detector geometry, material, sensitive
detector, and trigger setup has been specified.

After this point, Geant4 builds the geometry and physics state. Detector
component commands are generally not meant to be changed after initialization.

## Beam and particle-gun setup

```text
/gun/beam_momentum_spread 0.008
/gun/set_pathlength 23.5 m
/gun/set_vertexz -1.5 m
/gun/mode beamline_profile

/gun/particle mu+
/g4PSI/run/nr 920000
/gun/beam_momentum 160 MeV
/gun/seeds 1667471554 3348062791
```

| Command | Meaning | Current value |
|---|---|---:|
| `/gun/beam_momentum_spread` | Relative beam momentum spread. | `0.008` |
| `/gun/set_pathlength` | Flight path length of the channel to the target center. Used for beam timing/RF calculations. | `23.5 m` |
| `/gun/set_vertexz` | Z origin for beamline modes relative to target zero. | `-1.5 m` |
| `/gun/mode` | Selects the primary generator mode. | `beamline_profile` |
| `/gun/particle` | Selects the primary beam particle. | `mu+` |
| `/g4PSI/run/nr` | Sets the run number stored in run/cooker metadata. | `920000` |
| `/gun/beam_momentum` | Sets central beam momentum. | `160 MeV` |
| `/gun/seeds` | Sets random-number seeds for reproducible simulation. | `1667471554 3348062791` |

### Beamline profile mode

```text
/gun/mode beamline_profile
```

This uses the beamline-profile generator rather than a simple pencil beam. For
acceptance studies, this is usually better than:

```text
/gun/mode default
/gun/position 3.5 3.5 -2000 mm
/gun/direction 0 0 1
```

because it gives a more realistic input phase space. A pencil beam is useful
for debugging, but it can produce over-clean acceptance estimates.

### Momentum and spread

```text
/gun/beam_momentum 160 MeV
/gun/beam_momentum_spread 0.008
```

The central momentum is `160 MeV`. The spread is relative, so `0.008` means a
roughly `0.8%` momentum spread in the beam model.

If you train a model on this sample, momentum and momentum spread are part of
the data-generating process. A model trained only at `160 MeV` should not be
assumed valid for other beam momenta without additional samples.

### Seeds

```text
/gun/seeds 1667471554 3348062791
```

Seeds make the event sequence reproducible. For production sweeps, change the
seeds between statistically independent runs. For debugging, keep them fixed.

## ROOT output

```text
/g4PSI/run/rootfile runs/manual_muplus_160MeV/run001.root
```

This selects the output ROOT file. The output directory must already exist
before running g4PSI.

Use a unique output path per run. If multiple jobs write the same file, one job
can overwrite or corrupt another job's output.

## Event count

```text
/run/beamOn 1000
```

This starts the simulation and requests `1000` primary events.

| Event count | Use |
|---:|---|
| `1000` | Smoke test: checks that geometry, output, and recipes run. |
| `100000` | Small development sample. |
| `300000` or more | More realistic training/statistics sample. |
| Millions | Production-scale hazard-model sample, depending on acceptance and available compute. |

For termination-hazard modeling, the useful number is not just generated
events. It is the number of candidates at each stage:

```text
truth candidates
SPS-side candidates
BH-PID candidates
LUT5 candidates
TOF candidates
calo candidates
DOCA candidates
final accepted candidates
```

Rare late-stage failures often determine how many simulated events you need.

## Hazard-model relevance by macro section

| Macro section | Main role in data flow | Model relevance |
|---|---|---|
| Detector setup | Defines which simulated detector hits can exist. | Required for stage labels and features. |
| Detector parameters | Defines material, geometry, and alignment. | Changes acceptance and must be logged with training data. |
| Trigger definitions | Controls which events are written by g4PSI. | Can bias the denominator if not handled explicitly. |
| Beam/gun setup | Defines incoming particle species, momentum, spread, timing, and phase space. | Core truth features and training-domain definition. |
| RadGen controls | Defines radiative scattering phase space and sampling bias. | Requires event weights; defines angular/radiative domain. |
| ROOT output | Stores raw event data for cooker and custom exports. | Source for truth tables, stage tables, and validation. |
| `/run/beamOn` | Sets generated event count. | Controls statistical precision. |

## Suggested interpretation for acceptance modeling

For a simple binary classifier, the macro provides the raw simulation needed to
label:

```text
accepted_final = 0 or 1
```

For a termination hazard model, the same raw simulation should be exported into
stage-wise rows, for example:

```text
truth
SPS side
no veto
BH PID
LUT5
GEM track
tracklet
vertex
TOF
not decay/RID
calo
DOCA
final accepted
```

The macro alone does not produce the clean training table. It produces the raw
g4PSI ROOT input. The MUSE cooker recipes and custom exporters then transform
that into model-ready candidate and cutflow tables.

## Common edits

| Desired change | Macro command to edit | Notes |
|---|---|---|
| Change particle species | `/gun/particle` | Use values such as `mu+`, `mu-`, `e+`, or `e-` if supported by the build. |
| Change beam momentum | `/gun/beam_momentum` | Also consider whether RadGen ranges and model labels still apply. |
| Increase statistics | `/run/beamOn` | Use unique output files for each run. |
| Turn on RadGen angular bias | Uncomment `/g4PSI/radgen/...` lines | Use `EventInfo.weight` downstream. |
| Use forced radiative scattering | Run with `--rad3` | Command-line change, not macro change. |
| Debug geometry | Keep `testplane = yes` and use small `/run/beamOn` | Good for visual/diagnostic studies. |
| Production batch | Use stable seeds/output names and larger event count | Record the exact macro and command-line args with the output. |

## Checklist

| Check | Why |
|---|---|
| Output directory exists | g4PSI will not create nested output directories for you. |
| Output filename is unique | Avoid job collisions. |
| Seeds are intentional | Fixed seeds for reproducibility, changed seeds for independent runs. |
| Radiative mode is logged | `--rad3` versus `--rad1` changes the data-generating process. |
| RadGen settings are logged | Theta/phi/soft-fraction settings define the generated phase space and weights. |
| Event weights are exported | Required for unbiased training and validation. |
| Trigger prescale is understood | The trailing `1` means a factor-of-two prescale for each trigger branch. |
| Macro is archived with results | Needed to reproduce trained models. |
