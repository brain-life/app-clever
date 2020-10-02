[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![brainlife.io/app](https://img.shields.io/badge/brainlife.io-app-green.svg)](https://brainlife.io/app/5b2975d616fe38002748e79a)

# app-clever

`clever` computes principal Components LEVERage (“CLEVER”) and other measures of outlyingness for high-dimensional data such as fMRI data. In BrainLife, it can be used for flagging timepoints which are likely to contain artifacts ("scrubbing") as well as general quality-control of fMRI data.

### How it works

As input, `clever` takes an fMRI volume `"bold.nii.gz"` and brain mask `"mask.nii.gz"`, and applies the mask to form a ***T*** timepoints by ***V*** voxels matrix, ***Y***. In our case, ***Y*** represents an fMRI run: each row is a vectorized volume, and each column represents one timepoint. Next, the algorithm performs the following steps: 

1. Normalize ***Y*** by centering and scaling its columns robustly.

2. Perform PCA on the normalized ***Y*** matrix using the singular value decomposition (SVD) in order to obtain the ***T **x** T*** PC score matrix, ***U***.

3. Some PCs are removed from ***U*** to obtain the ***Q*** *x* ***T*** (***Q*** *<* ***T***) matrix, ***U'***. The PCs which are retained are those likley to contain outlier information: PCs with greater-than-average variance, or PCs with both greater-than-average variance and high kurtosis. (The removal of at least one PC is also a theoretical requirement for leverage; additionally, the robust distance method requires ***Q*** to be appropriately small relative to ***T***.)

4. Next, leverage and/or robust distance is measured. The output of each is a length ***T*** vector representing the "outlyingness" of each time point.  

5. The outlyingness measures are thresholded to identify the set of outlying timepoints. 

We also include the DVARS outlier detection method in `clever`. It normalizes the data as explained in step 1, but otherwise follows the algorithm as described in the [paper (Afyouni and Nichols, 2018)](doi.org/10.1016/j.neuroimage.2017.12.098) and implemented in the [MATLAB code](https://github.com/asoroosh/DVARS) provided by its authors.

### Authors

- [Amanda Mejia](afmejia@iu.edu)
- [John Muschelli](jmusche1@jhu.edu)
- [Damon Pham](ddpham@iu.edu)

### Funding Acknowledgement

brainlife.io is publicly funded and for the sustainability of the project it is helpful to Acknowledge the use of the platform. We kindly ask that you acknowledge the funding below in your publications and code reusing this code.

[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-ACI-1916518](https://img.shields.io/badge/NSF_ACI-1916518-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1916518)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://grantome.com/grant/NIH/R01-EB029272-01)

### Citations

We kindly ask that you cite the following articles when publishing papers and code using this code. 

1. Avesani, P., McPherson, B., Hayashi, S. et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. Sci Data 6, 69 (2019). [https://doi.org/10.1038/s41597-019-0073-y](https://doi.org/10.1038/s41597-019-0073-y)

# Running the App 

### On Brainlife.io

You can submit this App online at [https://doi.org/10.25663/bl.app.71](https://doi.org/10.25663/bl.app.71) via the "Execute" tab.

### Running Locally (on your machine)

For local use, we recommend using the R package directly. See the README at https://github.com/mandymejia/clever/tree/2.0 for installation instructions and a tutorial.

### Sample Datasets

`clever` includes two sample datasets, `Dat1` and `Dat2`. These are fMRI time series slices which have been vectorized (are ***T*** **x** ***V***).

### Output

All output files will be generated under the current working directory. The outputs of this App are `product.json` which plots the timecourse of each measure of outlyingness interactively using `plotly`, `cleverPlot.png` which plots the timecourse of each measure of outlyingness using the original plot method included with `clever`, and `cleverTable.csv` which stores each measure and outlier indication along the columns.

### Dependencies

This App only requires [singularity](https://www.sylabs.io/singularity/) to run. If you don't have singularity, you will need to install following dependencies.  

  - R: https://www.r-project.org/
  - The `clever` package itself: https://github.com/mandymejia/clever  
  - R package "Imports" listed here: https://github.com/mandymejia/clever/blob/master/DESCRIPTION
  - The `glmgen` R package: https://github.com/glmgen/glmgen
  - These other R packges: `oro.nifti`, `rjson`, `ggplot2`, and `cowplot`.

### GPL-v3 Copyright 