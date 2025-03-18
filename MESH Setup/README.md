# Mackenzie River Basin Setup
 
This is the final MESH setup of the Mackenzie River Basin (MRB) which was used to run the simulations for the historical run using GEM-CaPA data (2005-2016) and the climate and land cover/use change runs for the period 1951-2100 forced with the bias corrected downscaled scenarios (CanRCM4-WGC). Model setup and validation are described in this preprint (which is now accepted by the Journal of Hydrology):
https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4791947

A preprint showing climate and land cover/use change impacts on the MRB is also under review in Water Resources Research available at:
https://essopenarchive.org/doi/full/10.22541/essoar.173082837.77691678

This setup contains several files that are described briefly below:

MESH drainage databases - 4 draiange databases are used:
1. 08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2005_v5.4.PBSM.Pol0.01.LU.NoWilliston.r2c  Historical land cover, corrected to RGIv6, excludes Williston Researvoir, used for periods before the Bennett dam was built, i.e. prior to 1968 (only Reach field is edited)
2. 08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2005_v5.4.PBSM.Pol0.01.LU.r2c              Historical land cover, corrected to RGIv6, excludes Williston Researvoir, used for periods before the Bennett dam was built, from 1968 onwards
3. 08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2040_v5.4.PBSM.Pol0.01.LU.r2c              Near Future land cover scenario, used for the period 2021-2060
4. 08_MRB_Drainage_Database_MEAME_Real_24Lakes_15GRUs_ENWSW_Split_RGIv6_2085_v5.4.PBSM.Pol0.01.LU.r2c              Far Future land cover scenario, used for the period 2061-2100
   Netcdf versions of those files are included for easier visualization. These are also used by post-processing scripts. run_mesh.sh or run_mesh_.LU.sh scripts switche the database based on the selected periods and the given run mode (climate change only or climate change and land cover) which is controlled in the job script (mesh.slurm). The final ddb has 15 GRUs as named in the file and described in the paper.

MESH Parameter Files:
1. MESH_parameters_CLASS.PBSM.MRB15.mod32.template.ini                  CLASS parameters - template that gets edited by Settings.sh script to change a few settings (ZRFM, ZRFH, GRIDS)
2. MESH_parameters_hydrology.PBSM.MRB15.mod30.ini                       hydrology parameters
3. MRB_MESH_parameters.ODEP.Morg.uniform.zsnl-basin.r2c                 Distributed parameters: Drainage Density (DDEN), Slope (XSLP), Depth to Bedrock (SDEP), and soil texture (% SAND, % CLAY, % ORGM). Organic matter ceases after a depth called ODEP (max 11 layers based on the used soil layering file). Soil column is uniform. ZSNL is supplied by subbasin (See the first preprint and supplement)
4. coeff_reserv.1445.txt                                                Calibrated DZTR coefficients for the Bennet Dam
5. MESH_input_run_options.template.GC.nc.ini                            MESH input run options to be used with GEM-CaPA - This is a template that gets edited several times by the run_mesh.sh script. Some Settings are passed from Settings.sh script which is sourced within run_mesh.sh
6. MESH_input_run_options.template.WGC.nc.ini                           MESH input run options to be used with WGC and CanRCM4-WGC
7. MESH_input_reservoir.24.20230501.NoWilliston.tb0                     Lakes outflow parameters - Williston is not included. This file is used for periods ending prior to 1/1/1968 - last updated 2023/05/01
8. MESH_input_reservoir.24.20230501.tb0                                 Lakes outflow parameters - Williston is included. This file is used for periods starting 1/1/1968 or later - last updated 2023/05/01
9. MRB_278.1951-2020.20220331.tb0                                       MESH streamflow file for initializing channels and calculating metrics - contains 278 locations, mostly gauges, but some are points of interest that have no gauges. It spans the period 1951-2020 - last updated 2022/03/31
10. MESH_initial_values.20220922.r2c                                    Initial temperature and liquid & frozen soil moisture contents - spatially variable but vertically uniform. It is an attempt to make spin-up faster for permafrost simulations - last updated 2022/09/22
11. MESH_input_soil_levels.25L.txt                                      Soil layering File - 25 layers of thickness that increases with depth. Total depth of soil column 51.24m

Output Configuration Files:
1. outputs_balance.spin.txt                                            OUTFIELDSFLAG required output configurtion - Used for Spin-up cycles
2. outputs_balance.spin.txt                                            OUTFIELDSFLAG required output configurtion - Used for simulation
The output configuration files consider some outputs at the tile level, and thus contain entries for 15 GRUs. Some outputs maybe switched off to enhance speed.
