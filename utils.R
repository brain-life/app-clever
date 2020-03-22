# Represents NIfTI volume timeseries as matrix.
vectorize_NIftI = function(bold_fname, mask_fname, verbose=TRUE){
	if(verbose){ print('Reading mask.') }
	mask <- RNifti::readNifti(mask_fname, internal=FALSE)
	if(verbose){ print('Mask dims are:') }
	print(dim(mask))
	mask <- mask > 0
	nV <- sum(mask)
	if(verbose){ print(paste0('Mask density is ', round(nV/prod(dim(mask)), 2), '.')) }

	if(verbose){ print('Reading bold.') }
	dat <- RNifti::readNifti(bold_fname, internal=TRUE)
	if(verbose){ print(paste0('Bold dims are:')) }
	if(verbose){ print(dim(dat)) }
  if(!all(dim(dat)[1:3] == dim(mask)[1:3])){
    stop('Error: bold and mask dims do not match.')
  }
	nT <- dim(dat)[4]

	gc()

	if(verbose){ print(paste0('Initializing a matrix of size ', nT, ' by ', nV, '.')) }
	Dat <- matrix(NA, nT, nV)

	if(verbose){ print('Masking...') }
	for(t in 1:nT){
	  dat_t <- dat[,,,t]
	  Dat[t,] <- dat_t[mask]
	}
	if(verbose){ print('Finished masking.') }

	return(Dat)
}

# Creates a new file name from an existing one. Used to avoid duplicate names.
generate_fname = function(existing_fname){
	last_period_index <- regexpr("\\.[^\\.]*$", existing_fname)
	if(last_period_index == -1){ warning('Not a file name (no extension).') }
	extension <- substr(existing_fname, last_period_index, nchar(existing_fname))
	## If parenthesized number suffix exists...
	if(substr(existing_fname, last_period_index-1, last_period_index-1) == ')'){
		in_last_parenthesis <- gsub(
			paste0('(*\\))', extension), '',
			gsub('.*(*\\()', '', existing_fname))

		n <- suppressWarnings(as.numeric(in_last_parenthesis))
		if(is.numeric(n)){
			if(!is.na(n)){
				## ...add one.
				np1 <- as.character(n + 1)
				n <- as.character(n)
				out <- gsub(
						paste0( '(\\(', n, '\\))', extension),
						paste0('\\(', np1, '\\)', extension),
						existing_fname)
			}
		}
	} else {
		## Otherwise, append "(1)".
		out <- gsub(extension, paste0('(1)', extension), existing_fname)
	}
	## Try again if it still exists.
	if(file.exists(out)){ return(generate_fname(out)) }
	return(out)
}

# Represents a clever object as a JSON file.
clever_to_JSON = function(clev){
	msg.type <- 'success'
	msg.msg <- 'clever finished successfully!'
	if(clev$params$id_out){
		out_level.num <- apply(clev$outliers, 1, sum)
		out_level.max <- max(out_level.num)
		any_outliers <- out_level.max > 0
		msg.type <- ifelse(any_outliers, 'warning', 'success')
		msg.msg <- ifelse(any_outliers,
			paste0(msg.msg, ' ',
						 sum(out_level.num == out_level.max),
						 ' outliers were detected at the ',
						 colnames(clev$outliers)[out_level.max],
						 ' outlier level.'),
			paste0(msg.msg, ' No outliers were detected!')
		)
	}

	js <- list(
			brainlife=list(
				list(type=msg.type, msg=msg.msg),
				graph1=plotly_json(plot(clev), jsonedit=FALSE)
		)
	)
	js <- toJSON(js)
	return(js)
}

# Represents a clever object as a data.frame.
clever_to_table = function(clev){
	PCA_trend_filtering <- clev$params$PCA_trend_filtering
	choose_PCs <- clev$params$choose_PCs
	method <- clev$params$method
	PC_indices <- clev$PCs$indices
	measure <- switch(method,
		leverage=clev$leverage,
		robdist=clev$robdist,
		robdist_subset=clev$robdist)
	outliers <- clev$outliers
	cutoffs <- clev$cutoffs

	table <- data.frame(measure)
	if(!is.null(outliers)){
		table <- cbind(table, outliers)
	}
	names(table) <- c(
		paste0(
			ifelse(PCA_trend_filtering, 'TF PCs', 'PCs'),
			' selected by ', choose_PCs,
			', outliers selected by ', method, '.'),
		paste0(names(outliers), ' = ', cutoffs))
	if(!is.null(clev$in_MCD)){
		table <- cbind(table, in_MCD=clev$in_MCD)
	}
	return(table)
}

save_mat_img <- function(mat, fname){
	png(fname, width=960, height=as.integer(nrow(mat)/ncol(mat)*960))
	image(mat, col=hcl.colors(128, 'Grays', rev=TRUE), axes=FALSE, asp=1)
	dev.off()
}

save_lev_imgs <- function(lev_imgs, mask, out_dir='leverage_images'){
	# save Nifti files.
	save(lev_imgs, file='leverage_images.rda')

	# save image files.
	if(!dir.exists(out_dir)){ dir.create(out_dir) }
	mid <- as.integer(dim(mask) / 2)
	mid <- c(mid, rep(1, 4-length(mid)))
	for(i in 1:length(lev_imgs$top_dir)){
		t <- as.numeric(names(lev_imgs$top_dir))[i]
		save_mat_img(lev_imgs$mean[,,mid[3],i], paste0(out_dir, '/t', t, '_mean.png'))
		save_mat_img(lev_imgs$top[,,mid[3],i], paste0(out_dir, '/t,', t, '_top.png'))
	}
}
