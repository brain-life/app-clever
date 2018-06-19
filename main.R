#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
bold_filepath <- args[1]
mask_filepath <- args[2]
print(bold_filepath)
print(mask_filepath)

## load bold.nii.gz, and convert it to 2d matrix and pass run clever!

## convert output from clever to CSV and other data product
