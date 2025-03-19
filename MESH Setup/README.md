# Mackenzie River Basin Setup
 
This is the final MESH setup of the Mackenzie River Basin (MRB) which was used to run the simulations for the historical run using GEM-CaPA data (2005-2016) and the climate and land cover/use change runs for the period 1951-2100 forced with the bias corrected downscaled scenarios (CanRCM4-WGC). Model setup and validation are described in this preprint (which is now accepted by the Journal of Hydrology):
https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4791947

A preprint showing climate and land cover/use change impacts on the MRB is also under review in Water Resources Research available at:
https://essopenarchive.org/doi/full/10.22541/essoar.173082837.77691678

This setup contains several files that are described briefly below.

## MESH drainage databases

Four drainage databases are used:

1. [08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2005_v5.4.PBSM.Pol0.01.LU.NoWilliston.r2c](08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2005_v5.4.PBSM.Pol0.01.LU.NoWilliston.r2c): Historical land cover, corrected to RGIv6, excludes Williston Reservoir, used for periods before the Bennett dam was built, i.e. prior to 1968 (only Reach field is edited).
2. [08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2005_v5.4.PBSM.Pol0.01.LU.r2c](08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2005_v5.4.PBSM.Pol0.01.LU.r2c): Historical land cover, corrected to RGIv6, excludes Williston Researvoir, used for periods before the Bennett dam was built, from 1968 onwards.
3. [08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2040_v5.4.PBSM.Pol0.01.LU.r2c](08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2040_v5.4.PBSM.Pol0.01.LU.r2c): Near Future land cover scenario, used for the period 2021-2060.
4. [08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2085_v5.4.PBSM.Pol0.01.LU.r2c](08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2085_v5.4.PBSM.Pol0.01.LU.r2c): Far Future land cover scenario, used for the period 2061-2100.

NetCDF versions of these files are included for easier visualization. The NetCDF versions are also used by post-processing scripts.

[`run_mesh.sh`](run_mesh.sh) or [`run_mesh_.LU.sh`](run_mesh_.LU.sh) switch between the databases based on the selected periods and the given run mode (climate change only or climate change and land cover), which is controlled in the job script [`mesh.slurm`](mesh.slurm). The final drainage database has 15 GRUs as named in the file and described in the paper.

## MESH parameter files

1. [MESH_parameters_CLASS.PBSM.MRB15.mod32.template.ini](MESH_parameters_CLASS.PBSM.MRB15.mod32.template.ini): CLASS parameters - template that gets edited by the [`Settings.sh`](Settings.sh) script to change a few settings (`ZRFM`, `ZRFH`, number of grids).
2. [MESH_parameters_hydrology.PBSM.MRB15.mod30.ini](MESH_parameters_hydrology.PBSM.MRB15.mod30.ini): Hydrology parameters.
3. [MRB_MESH_parameters.ODEP.Morg.uniform.zsnl-basin.r2c](MRB_MESH_parameters.ODEP.Morg.uniform.zsnl-basin.r2c): Distributed parameters, including drainage density (`DDEN`), slope (`XSLP`), depth to bedrock (`SDEP`), and soil texture (%`SAND`, %`CLAY`, %`ORGM`). Organic matter ceases after a depth called `ODEP` (to a maximum of 11 layers based on the used soil layering file). The soil column is uniform. `ZSNL` is supplied by subbasin (see the first preprint and supplement).
4. [coeff_reserv.1445.txt](coeff_reserv.1445.txt): Calibrated `DZT`R coefficients for Bennet Dam.
5. [MESH_input_run_options.template.GC.nc.ini](MESH_input_run_options.template.GC.nc.ini): MESH input run options to be used with GEM-CaPA. This is a template that gets edited several times by the [`run_mesh.sh`](run_mesh.sh) script. Some Settings are passed from the [`Settings.sh`](Settings.sh) script, which is sourced within [`run_mesh.sh`](run_mesh.sh).
6. [MESH_input_run_options.template.WGC.nc.ini](MESH_input_run_options.template.WGC.nc.ini): MESH input run options to be used with WGC and CanRCM4-WGC.
7. [MESH_input_reservoir.24.20230501.NoWilliston.tb0](MESH_input_reservoir.24.20230501.NoWilliston.tb0): Lake outflow parameters. Williston is not included. This file is used for periods ending prior to January 1, 1968. - _Last updated 2023/05/01_
8. [MESH_input_reservoir.24.20230501.tb0](MESH_input_reservoir.24.20230501.tb0): Lakes outflow parameters. Williston is included. This file is used for periods starting January 1, 1968 or later. - _Last updated 2023/05/01_
9. [MRB_278.1951-2020.20220331.tb0](MRB_278.1951-2020.20220331.tb0): MESH streamflow file for initializing channels and calculating metrics. Contains 278 locations, mostly gauges, but some are points of interest that have no gauges. It spans the period 1951-2020. - _Last updated 2022/03/31_
10. [MESH_initial_values.20220922.r2c](MESH_initial_values.20220922.r2c): Initial temperature and liquid and frozen soil moisture contents - spatially variable but vertically uniform. It is an attempt to make spin-up faster for permafrost simulations. - _Last updated 2022/09/22_
11. [MESH_input_soil_levels.25L.txt](MESH_input_soil_levels.25L.txt): Soil layering file. The file contains 25 layers of thickness that increase with depth. The total depth of soil column `51.24`m.

## Output configuration files

1. [outputs_balance.spin.txt](outputs_balance.spin.txt): `OUTFIELDSFLAG` required output configurtion used for spin-up cycles.
2. [outputs_balance.run.txt](outputs_balance.run.txt): `OUTFIELDSFLAG` required output configurtion used for simulation.

The output configuration files consider some outputs at the tile level, and thus contain entries for 15 GRUs. Some outputs maybe switched off to enhance speed.
