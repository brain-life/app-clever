# Represents NIfTI volume timeseries as matrix.
vectorize_NIftI = function(bold, mask){

	print('Reading bold.')
	dat <- readNIfTI(bold, reorient=FALSE)
	print(paste0('Bold dims are:'))
	print(dim(dat))

	print('Reading mask.')
	mask <- readNIfTI(mask, reorient=FALSE)
	print('Mask dims are:')
	print(dim(mask))

	mask <- 1*(mask > 0)
	nT <- dim(dat)[4]
	nV <- sum(mask)

	print(gc(verbose=TRUE))

	print(paste0('\t Initializing a matrix of size ', nT, ' by ', nV, '.'))
	Dat <- matrix(NA, nT, nV)

	print('Beginning mask loop.')
	for(t in 1:nT){
	  dat_t <- dat[,,,t]
	  Dat[t,] <- dat_t[mask==1]
	}

	print('Ending mask loop.')

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
clever_to_json = function(clev, params.plot=NULL){
	choosePCs <- clev$params$choosePCs
	method <- clev$params$method
	measure <- switch(method,
		leverage=clev$leverage,
		robdist=clev$robdist,
		robdist_subset=clev$robdist)
	outliers <- clev$outliers
	cutoffs <- clev$cutoffs

	graph1 <- frame()
	graph1$layout <- frame()
	graph1$layout$xaxis <- frame()
	graph1$layout$yaxis <- frame()
	graph1$type <- "plotly"

	if(is.null(params.plot)){
		params.plot=list(main='', xlab='', ylab='')
	}

	graph1$name <- ifelse(params.plot$main != '', params.plot$main,
		paste0('Outlier Distribution',
			ifelse(sum(apply(outliers, 2, sum)) > 0, '', ' (None Identified)')))

	graph1$layout$xaxis$title <- ifelse(params.plot$xlab != '', params.plot$xlab,
		'Index (Time Point)')
	graph1$layout$xaxis$type <- "linear"

	graph1$layout$yaxis$title <- ifelse(params.plot$ylab != '', params.plot$ylab,
		method)
	graph1$layout$yaxis$type <- "linear"

	graph1$data <- list(list(y=round(measure, digits=5)))

	root <- frame()
	root$brainlife <- list(graph1)
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
