# Load required packages, installing if needed.
#pkg <- c('oro.nifti', 'rjson', 'clever', 'ggplot2')
#pkg.new <- pkg[!(pkg %in% installed.packages()[,'Package'])] #or from github?
#if(length(pkg.new)){ install.packages(pkg.new) }
#lapply(pkg, require, character.only = TRUE)
#rm(pkg, pkg.new)

library(RNifti)
library(rjson)
library(clever)
library(ggplot2)
library(plotly)
#library(listviewer)

source('utils.R')

# Read input from JSON.
input <- fromJSON(file = 'config.json')
input[input == ''] = NULL
if(!is.null(input$id_out)){ input$id_out <- as.logical(input$id_out) }
if(is.na(input$id_out)){ stop('Invalid "id_out" argument.') }
input$kurt_quantile_cut <- as.numeric(input$kurt_quantile_cut)
input$kurt_detrend <- as.logical(input$kurt_detrend)
input$id_out <- as.logical(input$id_out)
params.clever <- input[names(input) %in% c('choosePCs', 'kurt_quantile_cut', 'kurt_detrend',
																					 'method', 'id_out')]
params.plot <- input[names(input) %in% c('main','sub','xlab','ylab')]
opts <- input[names(input) %in% c('out_dir','csv','png')]
opts <- opts[is.null(opts)]

print('Garbage collection before doing anything:')
print(gc(verbose=TRUE))

# Vectorize data.
print('(1) Vectorizing...')
Dat <- vectorize_NIftI(input$bold, input$mask)
if(any(is.na(Dat))){ stop('Error: NA in vectorized volume.') }

print('Garbage collection after vectorizing bold:')
rm(input)
print(gc(verbose=TRUE))
print('Size of vectorized matrix:')
print(object.size(Dat), units='Mb')

# Perform clever.
print('(2) Performing clever...')
clev <- do.call(clever, append(list(Dat), params.clever))

# Save results...
print('(3) Saving results...')
## Use default options if unspecified.
cwd <- getwd()
if(is.null(opts$out_dir)){ opts$out_dir <- cwd }
if(!dir.exists(opts$out_dir)){dir.create(opts$out_dir)}
setwd(opts$out_dir)
fname <- 'clever_results'

if(is.null(opts$csv)){ opts$csv <- fname }
if(!endsWith('.csv', opts$csv)){ opts$csv <- paste0(opts$csv, '.csv') }
if(file.exists(opts$csv)){ opts$csv <- generate_fname(opts$csv) }
if(is.null(opts$png)){ opts$png <- fname }
if(!endsWith('.png', opts$png)){ opts$png <- paste0(opts$png, '.png') }
if(file.exists(opts$png)){ opts$png <- generate_fname(opts$png) }

if(params.clever$id_out){
	## Save to png.
	plt <- do.call(plot, append(list(clev), params.plot[is.null(params.plot)]))
	if(dirname(opts$png) != '.'){
		if(!dir.exists(dirname(opts$png))){dir.create(dirname(opts$png))}
	}
	ggsave(filename = opts$png, plot=plt)

	## Save to csv.
	table <- clever_to_table(clev)
	if(dirname(opts$csv) != '.'){
		if(!dir.exists(dirname(opts$csv))){dir.create(dirname(opts$csv))}
	}
	write.csv(table, file=opts$csv, row.names=FALSE)
}

## Write the JSON file.
root <- clever_to_json(clev, params.plot, opts$png)
write(toJSON(root), "product.json")

setwd(cwd)
