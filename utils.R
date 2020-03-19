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
clever_to_json = function(clev, params.plot=NULL, opts.png=NULL){
	root <- frame()
	root$brainlife <- list()
	root$brainlife$msg <- list(type='success', msg='Success!')
	root$brainlife$graph1 <- plotly_json(plot(clev), jsonedit=FALSE)

	return(root)
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
			', outliers selected by', choose_PCs, '.'),
		paste0(names(outliers), ' = ', cutoffs))
	if(!is.null(clev$in_MCD)){
		table <- cbind(table, in_MCD=clev$in_MCD)
	}
	return(table)
}
