process_color <- function(col, alpha=NA, sepia_intensity=0, saturation=1, color_vision_deficiency_sim="none") {
	#if (length(col)>100) browser()

	isFactor <- is.factor(col)

	if (isFactor) {
		x <- as.integer(col)
		col <- levels(col)
	}

	res <- t(col2rgb(col, alpha=TRUE))

	# set alpha values
	if (!is.na(alpha)) res[res[,4] != 0, 4] <- alpha * 255

	# convert to sepia
	if (sepia_intensity!=0) {
		conv_matrix <- matrix(c(.393, .769, .189,
								.349, .686, .168,
								.272, .534, .131), ncol=3, byrow=FALSE)
		res[,1:3] <-  (res[,1:3] %*% conv_matrix) * sepia_intensity + res[,1:3] * (1-sepia_intensity)
		res[res>255] <- 255
		res[res<0] <- 0
	}

	# convert to black&white
	if (saturation!=1) {
		res[,1:3] <- (res[,1:3] %*% matrix(c(.299, .587, .114), nrow=3, ncol=3))  * (1-saturation) + res[,1:3] * saturation
		res[res>255] <- 255
		res[res<0] <- 0
	}
	if (all(res[,4]==255)) res <- res[,-4, drop=FALSE]

	new_cols <- do.call("rgb", c(unname(as.data.frame(res)), list(maxColorValue=255)))

	rlang::check_installed("colorspace")
	# color blind sim
	sim_colors = switch(color_vision_deficiency_sim,
		deutan = colorspace::deutan,
		protan = colorspace::protan,
		tritan = colorspace::tritan,
		function(x) x)

	new_cols2 = sim_colors(new_cols)

	if (isFactor) {
		new_cols2[x]
	} else {
		new_cols2
	}
}

is_light <- function(col) {
	colrgb <- col2rgb(col)
	apply(colrgb * c(.299, .587, .114), MARGIN=2, sum) >= 128
}

get_light <- function(col) {
	colrgb <- col2rgb(col)
	apply(colrgb * c(.299, .587, .114), MARGIN=2, sum) / 255
}


darker <- function(colour, rate, alpha=NA) {
	col <- col2rgb(colour, TRUE)/255
	col[1:3] <- col[1:3] * (1-rate)
	if (is.na(alpha)) alpha <- col[4,]
	rgb(col[1, ], col[2, ], col[3, ], alpha)
}

lighter <- function(colour, rate, alpha=NA) {
	col <- col2rgb(colour, TRUE)/255
	col[1:3] <- col[1:3] + (1-col[1:3]) * rate
	if (is.na(alpha)) alpha <- col[4,]
	rgb(col[1, ], col[2, ], col[3, ], alpha)
}

col2hex <- function(x) {
	y <- apply(col2rgb(x), MARGIN=2, FUN=function(y)do.call(rgb, c(as.list(y), list(maxColorValue=255))))
	y[is.na(x)] <- NA
	y
}


# determine palette type
# palettes of length 1,2 or 3 are cat
# palette of length 4+ are seq if luminance is increasing or decreaing
# palette of length 5+ are div if luminance is increasing in first half and decreasing in second half, or the other way round.
palette_type <- function(palette) {
	k <- length(palette)
	if (k<4) return("cat")

	m1 <- ceiling(k/2) - 1
	m2 <- floor(k/2) + 1

	colpal_light <- get_light(palette)

	s <- sign(colpal_light[-1] - colpal_light[-k])

	if (all(s==1) || all(s==-1)) {
		return("seq")
	} else if (k>4 && ((all(s[1:m1]==1) && all(s[m2:(k-1)]==-1)) ||
		(all(s[1:m1]==-1) && all(s[m2:(k-1)]==1)))) {
		return("div")
	} else {
		return("cat")
	}
}


valid_colors <- function(x) {
	is.na(x) | (x %in% colors()) |	(vapply(gregexpr("^#(([[:xdigit:]]){6}|([[:xdigit:]]){8})$", x), "[[", integer(1), 1) == 1L)
}



# get_alpha_col <- function(colour, alpha=NA) {
# 	col <- col2rgb(colour, TRUE)/255
# 	if (is.na(alpha)) alpha <- col[4,]
# 	new_col <- rgb(col[1, ], col[2, ], col[3, ], alpha)
# 	new_col
# }
#
# get_sepia_col <- function(col, intensity=1) {
# 	conv_matrix <- matrix(c(.393, .769, .189,
# 							.349, .686, .168,
# 							.272, .534, .131), ncol=3, byrow=FALSE)
# 	colM <- t(col2rgb(col))
# 	res <-  (colM %*% conv_matrix) * intensity + colM * (1-intensity)
# 	res[res>255] <- 255
# 	do.call("rgb", c(unname(as.data.frame(res)), list(maxColorValue=255)))
# }
#
