# Represents NIfTI volume timeseries as matrix.
vectorize_NIftI = function(bold_fname, mask_fname, chunk_size=50){

	print('Reading mask.')
	mask <- RNifti::readNifti(mask_fname, internal=FALSE)
	print('Mask dims are:')
	print(dim(mask))
	mask <- mask > 0
	nV <- sum(mask)
	print(paste0('Mask density is ', round(nV/prod(dim(mask)), 2), '.'))

	if(is.null(chunk_size) | (chunk_size < 1)){
		print('Reading bold.')
		dat <- RNifti::readNifti(bold_fname, internal=TRUE)
		print(paste0('Bold dims are:'))
		print(dim(dat))
    if(dim(dat)[1:3] != dim(mask)[1:3]){
      stop('Error: bold and mask dims do not match.')
    }
		nT <- dim(dat)[4]

		gc()

		print(paste0('Initializing a matrix of size ', nT, ' by ', nV, '.'))
		Dat <- matrix(NA, nT, nV)

		print('Beginning mask loop.')
		for(t in 1:nT){
		  dat_t <- dat[,,,t]
		  Dat[t,] <- dat_t[mask]
		}
		print('Ended mask loop.')

	} else {
		stop('Chunkwise vectorizing does not work right now.')
		print('Reading bold in chunks.')
		bold_dims <- niftiHeader(bold_fname)$dim
		print(paste0('According to its header, bold dims are:'))
		print(bold_dims[2:5])
		nT <- bold_dims[5]

		print(paste0('Initializing a matrix of size ', nT, ' by ', nV, '.'))
		Dat <- matrix(NA, nT, nV)

		print('Beginning mask loop.')
		chunks <- split(1:nT, ceiling(seq_along(1:nT)/chunk_size))
		good_brick = 1
		for(i in 1:length(chunks)){
			ts = chunks[[i]]
			print(paste0('Chunk ', i, ':t ', ts[1], ' to ', ts[length(ts)]))
			dat <- tryCatch(
				expr = {
					x <- RNifti::readNifti(bold_fname, volumes=ts)
					good_brick = ts[1]
					x
				},
				error = {
					function(e){
						print(paste0('Warning: This chunk could not be read from t ', ts[1]))
						print(paste0('So, reading from ', good_brick, ' and taking subset.'))
						x <- RNifti::readNifti(bold_fname,
							volumes=good_brick:(ts[length(ts)]))
						return ( x[,,,ts-good_brick+1] )
					}
				}
			)
			for(i in 1:length(ts)){
				t <- ts[i]
			  dat_t <- dat[,,,i]
			  Dat[t,] <- dat_t[mask]
				rm(dat_t)
			}
			rm(dat)
		}

		print('Ended mask loop.')
	}

	return(Dat)
}

# Creates a new file name from an existing one. Used to avoid duplicate names.
generate_fname = function(existing_fname){
	last_period_index <- regexpr("\\.[^\\.]*$", existing_fname)
	if(last_period_index == -1){ warning('Not a file name (no extension).') }
	extension <- substr(existing_fname, last_period_index, nchar(existing_fname))
	## If parenthesized number suffix exists...
	if(substr(existing_fname, last_period_index-1, last_period_index-1) == ')'){
		in_last_parenthesis <- gsub(paste0('(*\\))', extension), '',
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
	}
	## Otherwise, append "(1)".
	out <- gsub(extension, paste0('(1)', extension), existing_fname)
	## Try again if it still exists.
	if(file.exists(out)){ return(generate_fname(out)) }
	return(out)
}

# Represents a clever object as a JSON file.
clever_to_json = function(clev, params.plot=NULL, opts.png=NULL){
	choosePCs <- clev$params$choosePCs
	method <- clev$params$method
	measure <- switch(method,
		leverage=clev$leverage,
		robdist=clev$robdist,
		robdist_subset=clev$robdist)
	outliers <- clev$outliers
	cutoffs <- clev$cutoffs

	root <- frame()
	root$brainlife <- list()

	if(!is.null(opts.png)){
		msg <- frame()
		msg$type <- "success"
		msg$msg <- "See clever_results.png for the outlier detection plot."
	}
	root$brainlife$msg <- msg

	#img <- frame()
	#img$type <- "image/png"
	#img$name <- "clever result"
  #img$base64 <- toJSON(plt) # does not work.

	graph1 <- frame()
	graph1$layout <- frame()
	graph1$layout$xaxis <- frame()
	graph1$layout$yaxis <- frame()
	graph1$type <- "plotly"
	if(is.null(params.plot)){
		params.plot=list(main=NULL, xlab=NULL, ylab=NULL)
	}
	graph1$name <- ifelse(!is.null(params.plot$main),
		params.plot$main,
		paste0('Outlier Distribution',
			ifelse(sum(apply(outliers, 2, sum)) > 0, '', ' (None Identified)')))
	graph1$layout$xaxis$title <- ifelse(!is.null(params.plot$xlab),
		params.plot$xlab,
		'Index (Time Point)')
	graph1$layout$xaxis$type <- "linear"
	graph1$layout$yaxis$title <- ifelse(!is.null(params.plot$ylab),
		params.plot$ylab,
		method)
	graph1$layout$yaxis$type <- "linear"
	graph1$data <- list(list(y=round(measure, digits=5)))
	root$brainlife$graph1 <- graph1
	return(root)
}

# Represents a clever object as a data.frame.
clever_to_table = function(clev){
	choosePCs <- clev$params$choosePCs
	method <- clev$params$method
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
		paste0(method, '. PCs chosen by ', choosePCs),
		paste0(names(outliers), ' = ', cutoffs))
	if(!is.null(clev$in_MCD)){
		table <- cbind(table, in_MCD=clev$in_MCD)
	}
	return(table)
}
