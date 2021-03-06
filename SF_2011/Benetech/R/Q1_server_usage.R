
library( plyr )
library(xtable)

#source( "load_data.R" )
# save( benetech.full, file="thedatafile.rdata" )
if ( FALSE ) {
	bk = benetech.full
	load( file="thedatefile" )
	benetech.full = bk
	table( benetech.full$server, benetech.full$original.server, useNA="ifany" )

	# for debugging -- speed up
	#benetech.full = benetech.full[ sample( 1:nrow(benetech.full), 5000 ), ]
}


# make sure we have ids for all the records
stopifnot( sum( is.na( benetech.full$public.code ) ) == 0 )
stopifnot( sum( is.na( benetech.full$bulletin.id ) ) == 0 )

#			sum.dat = ddply( benetech.full, c("server","original.server"), summarize,
#table( benetech.full$original.server )

# Cut up data by server.  For each server cut up by the original server
# and do summarize.  Also compute overall stats.
# Need to do this seperately to capture total unique across all records
# summing will give an invalid answer.
big.sum.list = dlply( benetech.full, "server", function( chunk ) {

	df = ddply( chunk, .(original.server), summarise,
		server=server[[1]],
		total.bull = length(public.code),
		total.Kb = sum( size..Kb. ),

		total.acc = length( unique( public.code ) ),
		attach.pub = sum( public.attachments ),
		attach.priv = sum( private.attachments )
		)
	if ( nrow(df) > 1 ) {
		df.full = ddply( chunk, .(server), summarise,
			original.server="Total",
			total.bull = length(public.code),
			total.Kb = sum( size..Kb. ),
	
			total.acc = length( unique( public.code ) ),
			attach.pub = sum( public.attachments ),
			attach.priv = sum( private.attachments )
			)
		df$original.server = c("Mirror","Orig")[1+df$original.server]
		df = df[ c(2,1,3:ncol(df)) ]
		rbind( df, df.full )
	} else {
		df$original.server = c("Total","Total")[1+df$original.server]
		df
	}
	
} )
summ = do.call( rbind, big.sum.list )
#summ

dups = !duplicated( summ$server )

# for pretty output
summ$server[!dups] = ""

# add some summary stats
summ$kBperBul = with( summ, total.Kb / total.bull )
summ $attach.tot = with( summ, attach.pub + attach.priv)
summ = summ[c(1,2,3,4,8,5,6,7,9)]

# not that useful?
#summ$avg.attach = with( summ, attach.tot / total.bull )

#summ


# make an xtable in latex.
xtb = xtable( summ, align="rrrrrrrrrr", caption="Database Usage Statistics",
			digits=0 )
print( xtb, hline.after=(which(dups)-1), include.rownames=FALSE,
		include.colnames=FALSE, only.contents=TRUE  )


