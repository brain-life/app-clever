library(oro.nifti)
library(rjson)
library(clever)
library(ggplot2)
library(cowplot)
theme_set(theme_cowplot())

source('utils.R')

# Read input from JSON.
input <- fromJSON(file = 'config.json')
input[input == ''] <- NULL # Remove unspecified params/options.
params.clever <- c(
	"projection", "out_meas", "DVARS", "detrend", "kurt_quant",
	"id_outliers", "lev_cutoff", "rbd_cutoff", "lev_images", "verbose"
)
params.clever <- input[names(input) %in% params.clever]
params.clever["projection"] <- strsplit(params.clever["projection"], ", ")[[1]]
params.clever["out_meas"] <- strsplit(params.clever["out_meas"], ", ")[[1]]
params.plot <- input[names(input) %in% c('main','sub','xlab','ylab')]
opts <- input[names(input) %in% c('csv','png')]
opts$out_dir <- getcwd()

# Vectorize data.
cat('vectorizing...\n')
dat <- readNIfTI(bold, reorient=FALSE)
stopifnot(length(dim(dat)) == 4)
cat("NIfTI dimensions:\n")
print(dim(dat))
mask <- readNIfTI(mask, reorient=FALSE)
dat <- t(matrix(dat[mask], ncol=dim(dat)[4]))

# Perform clever.
cat('performing clever...\n')
clev <- do.call(clever, append(list(X=dat), params.clever))

# Save results
cat('saving results...\n')
## Use default options if unspecified.
fname <- basename(input$mask)
for(ext in c('\\.gz$', '\\.nii$', '\\.hdr$', '\\.img$')){
	fname <- sub(ext, '', fname)
}
fname <- file.path(opts$out_dir, fname)
if (!dir.exists(dirname(fname))) { dir.create(dirname(fname)) }

if(is.null(opts$csv)){ opts$csv <- fname }
if(!endsWith('.csv', opts$csv)){ opts$csv <- paste0(opts$csv, '.csv') }
if(file.exists(opts$csv)){ opts$csv <- generate_fname(opts$csv) }
if(is.null(opts$png)){ opts$png <- fname }
if(!endsWith('.png', opts$png)){ opts$png <- paste0(opts$png, '.png') }
if(file.exists(opts$png)){ opts$png <- generate_fname(opts$png) }

if(params.clever$id_out){
	## Save to png.
	plt <- do.call(plot, append(list(clev), params.plot))
	ggsave(filename = opts$png, plot=plt)

	## Save to csv.
	table <- clever_to_table(clev)
	write.csv(table, file=opts$csv, row.names=FALSE)
}

## Write the JSON file.
root <- clever_to_json(clev, params.plot)
write(toJSON(root), "product.json")
