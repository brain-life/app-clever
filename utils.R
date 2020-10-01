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
	out_meas <- clev$outlier_measures
	methods <- names(out_meas)
	outliers <- clev$outlier_flags
	cutoffs <- clev$outlier_cutoffs

	graphs <- vector("list", length(methods))

	for (ii in 1:length(methods)) {
		method <- methods[ii]
		graph[[ii]] <- frame()
		graph[[ii]]$layout <- frame()
		graph[[ii]]$layout$xaxis <- frame()
		graph[[ii]]$layout$yaxis <- frame()
		graph[[ii]]$type <- "plotly"

		if(is.null(params.plot)){
			params.plot=list(main='', xlab='', ylab='')
		}

		graph[[ii]]$name <- ifelse(
			params.plot$main != '', 
			arams.plot$main,
			paste0(
				'Outlier Distribution',
				ifelse(
					sum(apply(outliers[[method]], 2, sum)) > 0, 
					'', 
					' (None Identified)'
				)
			)
		)

		graph[[ii]]$layout$xaxis$title <- ifelse(
			params.plot$xlab != '', 
			params.plot$xlab,
			'Index (Time Point)'
		)
		graph[[ii]]$layout$xaxis$type <- "linear"

		graph[[ii]]$layout$yaxis$title <- ifelse(
			params.plot$ylab != '', 
			params.plot$ylab,
			method
		)
		graph[[ii]]$layout$yaxis$type <- "linear"

		graph[[ii]]$data <- list(list(y=round(out_meas[[method]], digits=5)))	
	}

	root <- frame()
	root$brainlife <- graphs
	return(root)
}

# Represents a clever object as a data.frame.
clever_to_table = function(clev){
	out_meas <- clev$outlier_measures
	methods <- names(out_meas)
	outliers <- clev$outlier_flags
	cutoffs <- clev$outlier_cutoffs

	m_DVARS <- grepl("DVARS", names(out_meas))

	out_meas <- cbind(
		data.frame(out_meas[!m_DVARS]),
		rbind(0, data.frame(out_meas[m_DVARS]))
	)
	names(out_meas) <- paste0(out_meas, ", Measure")
	if(!is.null(outliers)){
		outliers <- cbind(
			data.frame(outliers[!m_DVARS]),
			rbind(0, data.frame(outliers[m_DVARS]))
		)
		names(outliers) <- paste0(
			outliers, " Cutoff: ", 
			round(unlist(clever.Dat1$outlier_cutoffs), 3)
		)
		out_meas <- cbind(out_meas, outliers)
	}

	out_meas
}
