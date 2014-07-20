working.dir <- "F:/R/Crawler"
setwd(working.dir)

library(XML)
library(RCurl)
library(plyr)

options(encoding="Shift-JIS")
options("encoding")

# 2ちゃんねる「死ぬ程洒落にならない怖い話を集めてみない？320」
url <- "http://toro.2ch.sc/test/read.cgi/occult/1397557403/"

lines <- readLines(url,encoding ="Shift-JIS")
str.lines <- iconv(x=lines,from="Shift-JIS",to="UTF-8")

query <- paste0(str.lines,collapse="")

obj <- htmlParse(query,encoding="UTF-8")
posted <- getNodeSet(obj,"//dt")
comments <- getNodeSet(obj,"//dl/dd")

# 投稿者情報のparse
lst <- list()
for(post in posted){
  str <- xmlValue(post)
  vec.str <- unlist(strsplit(x=str,split=" ："))
  vec.str <- unlist(strsplit(x=vec.str,split="：20"))
  vec.str <- unlist(strsplit(x=vec.str,split="ID:"))
  lst[[vec.str[1]]] <- vec.str
}
vec.temp <- sapply(lst,length)
is.valid.post <- which(vec.temp==4) # ID,Contributor,Date,Hashが揃う投稿のみを有効とみなす
df.posted <- ldply(lst[is.valid.post])[,-1]
colnames(df.posted) <- c("ID","Contributor","Date","HashID")

# 投稿内容のparse
## ダブルスペースを改行する場合は，is.return=TRUEに設定
is.return <- TRUE
vec.comments <- sapply(comments,function(comment){xmlValue(comment,trim=T)})
if(is.return){
  vec.comments <- gsub(x=vec.comments,pat="  ",rep="\n")
}

# 投稿者情報と結合
df.posted$comment <- vec.comments[is.valid.post]

# CSVファイルに書き出し
title.node <- getNodeSet(obj,"//title")
title <- xmlValue(title.node[[1]])
file.name <- paste0(title,".csv")
write.csv(x=df.posted,file=file.name,row.names=FALSE)
