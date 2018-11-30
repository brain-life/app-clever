# Load required packages, installing if needed.
pkg <- c('oro.nifti', 'rjson', 'clever', 'ggplot2')
pkg.new <- pkg[!(pkg %in% installed.packages()[,'Package'])] #or from github?
if(length(pkg.new)){ install.packages(pkg.new) }
lapply(pkg, require, character.only = TRUE)
rm(pkg, pkg.new)

source('utils.R')

# Read input from JSON.
input <- fromJSON(file = 'config.json')
if(input$id_out != ''){ input$id_out <- as.logical(input$id_out) }
if(is.na(input$id_out)){ stop('Invalid "id_out" argument.') }
input[input == ''] <- NULL # Remove unspecified params/options.
params.clever <- input[names(input) %in% c('choosePCs','method','id_out')]
params.plot <- input[names(input) %in% c('main','sub','xlab','ylab')]
opts <- input[names(input) %in% c('out_dir','csv','png')]

# Vectorize data.
print('vectorizing...')
Dat <- vectorize_NIftI(input$bold, input$mask)

# Perform clever.
print('performing clever...')
clev <- do.call(clever, append(list(Dat), params.clever))

# Save results...
print('saving results...')
## Use default options if unspecified.
cwd = getwd()
if(is.null(opts$out_dir)){ opts$out_dir <- cwd }
if(!dir.exists(opts$out_dir)){dir.create(opts$out_dir)}
setwd(opts$out_dir)
fname <- basename(input$mask)
for(ext in c('\\.gz$', '\\.nii$', '\\.hdr$', '\\.img$')){
	fname <- sub(ext, '', fname)
}
if(is.null(opts$csv)){ opts.csv <- fname }
if(!endsWith('.csv', opts$csv)){ opts$csv <- paste0(opts$csv, '.csv') }
if(is.null(opts$png)){ opts.png <- fname }
if(!endsWith('.png', opts$png)){ opts$png <- paste0(opts$png, '.png') }

if(params.clever$id_out){
	## Save to png.
	plt <- do.call(plot, append(list(clev), params.plot))
	ggsave(filename = opts$png, plot=plt)

	## Save to csv.
	table <- clever_to_table(clev)
	write.csv(table, file=opts$csv, row.names=FALSE)
}

## Write the JSON file.
root = clever_to_json(clev, params.plot)
write(toJSON(root), "product.json")

setwd(cwd)