# Represents NIfTI volume timeseries as matrix.
vectorize_NIftI = function(bold, mask){
	dat <- readNIfTI(bold)
	mask <- readNIfTI(mask)
	mask <- 1*(mask > 0)
	T <- dim(dat)[4]
	V <- sum(mask)

	Dat <- matrix(NA, T, V)
	for(t in 1:T){
	  dat_t <- dat[,,,t]
	  Dat[t,] <- dat_t[mask==1]
	}

	return(Dat)
}

# Creates a new file name from an existing one. Used to avoid duplicate names. 
generate_fname = function(existing_fname){
	last_period_index <- regexpr("\\.[^\\.]*$", existing_fname)
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
clever_to_json = function(clev, params.plot){
	choosePCs <- clev$params$choosePCs
	method <- clev$params$method
	measure <- switch(method,
		leverage=clev$leverage,
		robdist=clev$robdist,
		robdist_subset=clev$robdist)
	outliers <- clev$outliers
	cutoffs <- clev$cutoffs

	plot1 <- frame()
	plot1$x <- 1:length(method)
	plot1$y <- measure

	graph1 <- frame()
	graph1$layout <- frame()
	graph1$layout$xaxis <- frame()
	graph1$layout$yaxis <- frame()
	graph1$type <- "ggplot"

	graph1$name <- ifelse(!params.plot$main == '', params.plot$main,
		paste0('Outlier Distribution', 
			ifelse(sum(out$outliers$outliers) > 0, '', ' (None Identified)')))

	graph1$layout$xaxis$title <- ifelse(!params.plot$xlab == '', params.plot$xlab,
		'Index (Time Point)')
	graph1$layout$xaxis$type <- "linear"

	graph1$layout$yaxis$title <- ifelse(!params.plot$ylab == '', params.plot$ylab,
		method)
	graph1$layout$yaxis$type <- "linear"

	graph1$data <- c(plot1)

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