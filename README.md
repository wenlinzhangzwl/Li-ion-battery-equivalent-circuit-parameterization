# Li-ion-battery-equivalent-circuit-parameterization
Parameterizes a 1st, 2nd or 3rd order ECM using two methods. 

This set of scripts is developed at McMaster University by Wenlin Zhang (zhanw9@mcmaster.ca). A video recording of the tutorial can be found at (at the bottom of the page): https://hevpdd.ca/fall-2022-hevpdd-create-and-eecomobility-conference/
Two methods - directly and analytical - are used to parameterize a first, second or third order ECM.

Please cite: Zhang, W., Ahmed, R., Habibi, S., 2022. The Effects of Test Profile on Lithium-ion Battery Equivalent-Circuit Model Parameterization Accuracy, in: 2022 IEEE Transportation Electrification Conference & Expo (ITEC). Presented at the 2022 IEEE Transportation Electrification Conference & Expo (ITEC), pp. 119–124. https://doi.org/10.1109/ITEC53557.2022.9814019


/*********************************************************************************************************************************
Folder "\scripts" contains three main files: 
"parameterization_direct.m": Parameterize the ECM using the direct mehtod. 
"parameterization_analytical.m": Parameterize the ECM using the analytical mehtod. The user is required to install MathWorks' Powertrain Blockset (https://www.mathworks.com/products/powertrain.html) before running this script. 
"batterymodel_run.m": Runs the ECM with previously obtained parameters. 

Folder "\data" contains example data collected from a EVE280 LFP battery whose data sheet is also included in this package.
All tests are performed at 25 degC after a full charge.
Pulse tests (PUL) are performed with various rest lengths from 1 minute to 60 minutes. 
Drive cycle tests (UDDS, US06, HWFET, NEDC, MIX) are scaled such that the maximum absolute current is 0.8C. 
Capacity test (CAP) is performed at 0.5C. 
The files are named as follows: test_temperature_C rate_(rest length)

Parameterization results are saved at "\results".
