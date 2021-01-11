##################################################################################################
# Auxiliar functions 
# Author: Ramon Gustavo Teodoro Marques da Silva - ramongsilva@yahoo.com.br



# Function to eliminate whitespaces
trim <- function(x) {
  gsub("(^[[:space:]]+|[[:space:]]+$)","",x)
}

# Function to cut whitespaces
countWhiteSpaces <- function(x) attr(gregexpr("(?<=[^ ])[ ]+(?=[^ ])", x, perl = TRUE)[[1]], "match.length")

# Clean pubmed abstracts
cleanFun <- function(htmlString) {

  htmlString = gsub("[&]", "", htmlString)
  htmlString = gsub("[;]", "", htmlString)
  htmlString = gsub("<.*?>", "", htmlString)
  htmlString = gsub("tumour","tumor", htmlString)
  htmlString = gsub("tumours","tumors", htmlString)
  return(htmlString)
}
