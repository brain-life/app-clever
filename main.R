library(RNifti)
library(rjson)
library(clever)
library(ggplot2)
library(plotly)
library(robustbase)

source('utils.R')

# Read input from JSON.
input <- fromJSON(file = 'config.json')
input[input == ''] = NULL
input$PCA_trend_filtering <- as.logical(input$PCA_trend_filtering)
input$kurt_quantile <- as.numeric(input$kurt_quantile)
input$kurt_detrend <- as.logical(input$kurt_detrend)
input$id_out <- as.logical(input$id_out)
input$lev_img_lvl <- as.numeric(input$lev_img_lvl)
input$verbose <- as.logical(input$verbose)
params.clever <- input[names(input) %in% c(
	'PCA_trend_filtering', 'PCA_trend_filtering.kwargs', 'choose_PCs',
	'kurt_quantile', 'kurt_detrend', 'method', 'id_out', 'lev_img_lvl',
	'verbose')]
params.plot <- input[names(input) %in% c('main','sub','xlab','ylab')]
opts <- input[names(input) %in% c('csv','png')]

gc()

# Vectorize data.
print('(1) Vectorizing...')
Dat <- vectorize_NIftI(input$bold, input$mask)
if(any(is.na(Dat))){ stop('Error: NA in vectorized volume.') }

print('Garbage collection after vectorizing bold:')
print(gc(verbose=TRUE))
print('Size of vectorized matrix:')
print(object.size(Dat), units='Mb')

# Perform clever.
print('(2) Performing clever...')
clev <- do.call(clever, append(list(Dat), params.clever))

# Save results...
print('(3) Saving results...')
if(is.null(opts$csv)){ opts$csv <- 'cleverTable' }
if(!endsWith('.csv', opts$csv)){ opts$csv <- paste0(opts$csv, '.csv') }
if(file.exists(opts$csv)){ opts$csv <- generate_fname(opts$csv) }
if(is.null(opts$png)){ opts$png <- 'cleverPlot' }
if(!endsWith('.png', opts$png)){ opts$png <- paste0(opts$png, '.png') }
if(file.exists(opts$png)){ opts$png <- generate_fname(opts$png) }

# 	Save to png.
plt <- do.call(plot, append(list(clev), params.plot[!is.null(params.plot)]))
ggsave(filename = opts$png, plot=plt)

# 	Save to csv.
table <- clever_to_table(clev)
write.csv(table, file=opts$csv, row.names=FALSE)

# 	Write the plotly JSON file.
js <- clever_to_JSON(clev)
write(js, "product.json")

#		Make leverage images.
if(input$lev_img_lvl > 0){
	lev_imgs <- clev$lev_imgs
	if(length(lev_imgs$top_dir) > 1){
		mask <- RNifti::readNifti(input$mask, internal=FALSE)
		lev_imgs$mean <- RNifti::asNifti(
			Matrix_to_VolumeTimeSeries(lev_imgs$mean, mask),
			reference=input$mask)
		lev_imgs$top <- RNifti::asNifti(
			Matrix_to_VolumeTimeSeries(lev_imgs$top, mask),
			reference=input$mask)
		save_lev_imgs(lev_imgs)
	} else {
			print(paste0('No leverage images: no outliers detected at outlier level ',
									 input$leverage_images, '.'))
	}
}
