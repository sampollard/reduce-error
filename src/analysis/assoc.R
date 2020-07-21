t1 <- c("abcd","bacd","abdc","badc","dcab","dcba","cdab","cdba") # Symmetric
t2 <- c("abcd","bacd","cabd","cbad","dabc","dbac","dcba","dbac") # Mirror t3
t3 <- c("abcd","abdc","cdba","dcba","acdb","adcb","bcda","bdca") # Mirror t2
t4 <- c("abcd","acbd","adbc","adcb","bcda","cbda","dbca","dcba") # Mirror t5
t5 <- c("abcd","acbd","dabc","dacb","dbca","dcba","bcad","cbad") # Mirror t4
u <- unique(sort(c(t1,t2,t3,t4,t5))) # = 22
cat(paste(u, collapse = "\n"))
