##################################################################################################
# Named Entity Recognition in pubmed abstracts about polyphenols anticancer activity
# Author: Ramon Gustavo Teodoro Marques da Silva - ramongsilva@yahoo.com.br

#Import libraries
library(plyr) 
library(DBI)
library(RMySQL)
library(RCurl)
library(RSQLite)
library(stringr)
library(XML)
library(rJava)
library(qdap)
library(reshape)
library(reshape2)
library(tm)
library(data.table)


#Setting the folder with files 
setwd("/project-folder/")
source("functions.R")


#############################################################################################
# Retrieving of data in SQLite database
# Retrieving the  textual corpus with pubmed abstracts classified about cancer activity
drv = dbDriver("SQLite")
con = dbConnect(drv,dbname="db_total_project.db")
sql_articles <- str_c("SELECT * FROM articles_ensemble",sep="")	
res_articles <- dbSendQuery(con, sql_articles)
df_articles_positives <- fetch(res_articles, n = -1)
dbDisconnect(con)
df_articles_positives$med2 = (df_articles_positives$SVM_PROB + df_articles_positives$FORESTS_PROB + df_articles_positives$MAXENTROPY_PROB) / 3
df_articles = df_articles_positives

newdata <- df_articles_positives[order(-df_articles_positives$med),] 
rownames(newdata) = c(1:nrow(newdata))
lista_articles = newdata[c(1:10),1]

# Retrieving and pre-processing of synonyms about cancer entities
drv = dbDriver("SQLite")
con = dbConnect(drv,dbname="db_total_project.db")
sql_articles <- str_c("SELECT * FROM type_cancer_terms INNER JOIN type_cancer_equivalence_terms ON type_cancer_terms.idterm_descritor = type_cancer_equivalence_terms.term_descritor_idterm_descritor",sep="")	
res_articles <- dbSendQuery(con, sql_articles)
df_terms_equivalence <- fetch(res_articles, n = -1)
df_terms_equivalence$equivalence_term = tolower(df_terms_equivalence$equivalence_term)
df_terms_equivalence$equivalence_term2 = removePunctuation(df_terms_equivalence$equivalence_term)
dbDisconnect(con)

# Retrieving of terms about HGNC genes entities 
drv = dbDriver("SQLite")
con = dbConnect(drv,dbname="db_total_project.db")
sql_articles <- str_c("SELECT * FROM genes_hgnc",sep="")	
res_articles <- dbSendQuery(con, sql_articles)
df_terms_hgnc <- fetch(res_articles, n = -1)
dbDisconnect(con)

# Retrieving and pre-processing of synonyms about genes entities
drv = dbDriver("SQLite")
con = dbConnect(drv,dbname="db_total_project.db")
sql_articles <- str_c("SELECT * FROM gene_equivalence_terms",sep="")	
res_articles <- dbSendQuery(con, sql_articles)
df_terms_genes_equivalence <- fetch(res_articles, n = -1)
df_terms_genes_equivalence$equivalence_term = tolower(df_terms_genes_equivalence$equivalence_term)
df_terms_genes_equivalence$equivalence_term2 = removePunctuation(df_terms_genes_equivalence$equivalence_term)
dbDisconnect(con)

# Retrieving and pre-processing of synonyms about polyphenols entities
drv = dbDriver("SQLite")
con = dbConnect(drv,dbname="db_total_project.db")
sql_articles <- str_c("SELECT * FROM chemical_terms INNER JOIN chemical_equivalence_terms ON chemical_terms.idterm_descritor = chemical_equivalence_terms.term_descritor_idterm_descritor",sep="")	
res_articles <- dbSendQuery(con, sql_articles)
df_terms_chemical_equivalence <- fetch(res_articles, n = -1)
df_terms_chemical_equivalence$equivalence_term = tolower(df_terms_chemical_equivalence$equivalence_term)
df_terms_chemical_equivalence$equivalence_term2 = removePunctuation(df_terms_chemical_equivalence$equivalence_term)
dbDisconnect(con)



#############################################################################################
# NER - Named Entity Recognition
start_time <- Sys.time()
c_iguais = 0
c_iguais_gene = 0
c_iguais_chemical = 0
c_iguais_drug = 0
c_species = 0
c_achados_cellline = 0
c_achados_cancer = 0
c_achados_genes = 0
c_achados_chemical = 0
c_achados_drug = 0
Lista_achados_cancer = list()
Lista_achados_gene = list()
Lista_species = list()
Lista_achados_cellline = list()
Lista_achados_chemical = list()
Lista_achados_drug = list()
Lista_entity_encontrada_PubTator = list()
Lista_entity_BD = list()
Lista_entity_e_BD = list()
Lista_entity_ID = list()
Lista_entity_mesh_id = list()
Lista_entity_start_pos = list()
Lista_entity_end_pos = list()
Lista_entity_type = list()
Lista_entity_PMID = list()
lst_pmid = list()
lst_abstract = list()
lst_abstract_original = list()
lst_size_title = list()
c_artigo_com_relacao = 0 
c_artigo_sem_relacao = 0
lst_pmids = list()
lst_sentences_2 = list()
lst_sentences_3 = list()
lst_orinal_sentences = list()
lst_association = list()
lst_entitie = list()
lst_conclusion = list()
lst_title = list()
lst_start_pos = list()
lst_end_pos = list()
d = 0
c_articles_diference_sentences = 0
lst__articles_diference_sentences = list()
# Regular expression to find sentences about results and/or conlusion of pubmed abastracts
reg_expression_conclusion = '(results|findings|conclusion|data|taken|together|study|studies)[\\w]*(.*)(suggest|indicate|suggested|indicated|illustrated|illustrate|revealed)[\\w]*'
lst_categories = list(meshid = c('D007249','D009336','D063646','D007153'), categorie = c('inflammation','necrose','carcinogenese','immunologic_deficiency'))

for(z in 1:length(lista_articles)){
  
  pmid = lista_articles[z]
  #URL for retrieving recognized entities using pubtator API.
  url_busca = str_c('https://www.ncbi.nlm.nih.gov/research/pubtator-api/publications/export/pubtator?pmids=',pmid,'')
  linhas = readLines(url_busca)
  cat('\n **************************')
  
  if(length(linhas) > 0){
    
        for(i in 1:length(linhas)){
          
          if((i == 1)){ 
            linha = strsplit(linhas[i], "\\|")
            titulo = trim(linha[[1]][3])
            titulo_size =  nchar(titulo)
          }
          if((i == 2)){ 
            linha = strsplit(linhas[i], "\\|")
            texto = str_c(titulo,trim(linha[[1]][3]))
            texto_original = texto
            
          }
          
          linha = strsplit(linhas[i], "\\t")
          Tipo = trim(linha[[1]][5])
          
          if(!is.na(Tipo)){
            cat('\nTipo = ',Tipo)
          
      ##############################################################    
      # Finding for diseases entities about cancer using MESH ID     
              if(Tipo == 'Disease'){
                  MeshID = unlist(strsplit(linha[[1]][6], ":"))
                  MeshID = trim(MeshID[2])
                  if(!is.na(MeshID)){
                    PMID = linha[[1]][1]
                    pos1 = as.numeric(linha[[1]][2])
                    pos2 = as.numeric(linha[[1]][3])
                    termo = linha[[1]][4]
                    if(MeshID %in% df_terms_equivalence$term_id_mesh){
                      for(x in 1:nrow(df_terms_equivalence)){
                        MeshID_DB = trim(df_terms_equivalence$term_id_mesh[x])
                        termo_DB = trim(df_terms_equivalence$term_description[x])
                        if(!is.na(MeshID_DB)){
                          if(MeshID == MeshID_DB){
                            cat('\n #########################')
                            cat('\n MeshID_DB   = ',MeshID)
                            cat('\n MeshID      = ',MeshID_DB)
                            cat('\n POS1        = ',pos1)
                            cat('\n POS2        = ',pos2)
                            cat('\n Termo       = ',termo)
                            cat('\n Termo_DB    = ',termo_DB)
      
                            size = pos2 - pos1 
                            termo_troca <- format("D&S", width = size, justify = "c")
                            substr(texto, pos1, pos2) <- termo_troca
                            
                            c_iguais = c_iguais + 1
                            Lista_entity_encontrada_PubTator[c_iguais] = termo
                            Lista_entity_BD[c_iguais] = termo_DB
                            Lista_entity_e_BD[c_iguais] = termo_DB
                            Lista_entity_ID[c_iguais] = df_terms_equivalence$idterm_descritor[x]
                            Lista_entity_mesh_id[c_iguais] = MeshID
                            Lista_entity_start_pos[c_iguais] = pos1
                            Lista_entity_end_pos[c_iguais] = pos2
                            Lista_entity_type[c_iguais] = "cancer_type_entity_p"
                            Lista_entity_PMID[c_iguais] = PMID
                            break()
                          }
                        }
                      }
                    }
                    else if(MeshID %in% lst_categories$meshid){
                      
                      cat('\n #########################')
                      c_iguais = c_iguais + 1
                      Lista_entity_encontrada_PubTator[c_iguais] = termo
                      Lista_entity_BD[c_iguais] = termo
                      Lista_entity_e_BD[c_iguais] = termo
                      Lista_entity_ID[c_iguais] = MeshID
                      Lista_entity_mesh_id[c_iguais] = MeshID
                      Lista_entity_start_pos[c_iguais] = pos1
                      Lista_entity_end_pos[c_iguais] = pos2
                      Lista_entity_type[c_iguais] = "hallmark"
                      Lista_entity_PMID[c_iguais] = PMID
                      
                    }
                    else if((tolower(termo) %in% df_terms_equivalence$equivalence_term) | (tolower(termo) %in% df_terms_equivalence$equivalence_term2)){
                        for(y in 1:nrow(df_terms_equivalence)){
                          if((tolower(termo) == df_terms_equivalence$equivalence_term[y]) | (tolower(termo) == df_terms_equivalence$equivalence_term2[y])){
                            cat('\n #########################')
                            size = pos2 - pos1 
                            termo_troca <- format("D&S", width = size, justify = "c")
                            substr(texto, pos1, pos2) <- termo_troca
                            
                            c_iguais = c_iguais + 1
                            Lista_entity_encontrada_PubTator[c_iguais] = termo
                            Lista_entity_BD[c_iguais] = df_terms_equivalence$term_description[y]
                            Lista_entity_e_BD[c_iguais] = df_terms_equivalence$equivalence_term[y]
                            Lista_entity_ID[c_iguais] = df_terms_equivalence$idterm_descritor[y]
                            Lista_entity_mesh_id[c_iguais] = df_terms_equivalence$term_id_mesh[y]
                            Lista_entity_start_pos[c_iguais] = pos1
                            Lista_entity_end_pos[c_iguais] = pos2
                            Lista_entity_type[c_iguais] = "cancer_type_entity_e"
                            Lista_entity_PMID[c_iguais] = PMID
                            break()
                          }
                        }
                    }
                  }
      ##############################################################    
      # Finding for Cellline entities about cancer using MESH ID
              }else if(Tipo == 'CellLine'){
                    CVCL_ID = unlist(strsplit(linha[[1]][6], ":"))
                    CVCL_ID = trim(CVCL_ID[2])
                    if(!is.na(CVCL_ID)){
                      PMID = linha[[1]][1]
                      pos1 = as.numeric(linha[[1]][2])
                      pos2 = as.numeric(linha[[1]][3])
                      termo = linha[[1]][4]
                      if((tolower(termo) %in% df_terms_equivalence$equivalence_term) | (tolower(termo) %in% df_terms_equivalence$equivalence_term2)){
                        
                        for(y in 1:nrow(df_terms_equivalence)){
                          if((tolower(termo) == df_terms_equivalence$equivalence_term[y]) | (tolower(termo) == df_terms_equivalence$equivalence_term2[y])){
                            cat('\n #########################')
                            size = pos2 - pos1 
                            termo_troca <- format("D&S", width = size, justify = "c")
                            substr(texto, pos1, pos2) <- termo_troca
                            
                            c_iguais = c_iguais + 1
                            Lista_entity_encontrada_PubTator[c_iguais] = termo
                            Lista_entity_BD[c_iguais] = df_terms_equivalence$term_description[y]
                            Lista_entity_e_BD[c_iguais] = df_terms_equivalence$equivalence_term[y]
                            Lista_entity_ID[c_iguais] = df_terms_equivalence$idterm_descritor[y]
                            Lista_entity_mesh_id[c_iguais] = df_terms_equivalence$term_id_mesh[y]
                            Lista_entity_start_pos[c_iguais] = pos1
                            Lista_entity_end_pos[c_iguais] = pos2
                            Lista_entity_type[c_iguais] = "cancer_type_entity_cell"
                            Lista_entity_PMID[c_iguais] = PMID
                            break()
                          }
                        }
                      }
                    }
      ##############################################################            
      # Finding for genes entities about genes using HGNC
                }else if(Tipo == 'Gene'){
                        HGNC_ID = linha[[1]][6]
                        if(!is.na(HGNC_ID)){
                          PMID = linha[[1]][1]
                          pos1 = as.numeric(linha[[1]][2])
                          pos2 = as.numeric(linha[[1]][3])
                          termo = linha[[1]][4]
                          if(HGNC_ID %in% df_terms_hgnc$entrez_id){
                              for(x in 1:nrow(df_terms_hgnc)){
                                HGNC_ID_DB = trim(df_terms_hgnc$entrez_id[x])
                                termo_DB = trim(df_terms_hgnc$symbol[x])
                                if(!is.na(HGNC_ID_DB)){
                                  
                                  if(HGNC_ID == HGNC_ID_DB){
                                    cat('\n #########################')
                                    
                                    size = pos2 - pos1 
                                    termo_troca <- format("G&N", width = size, justify = "c")
                                    substr(texto, pos1, pos2) <- termo_troca
                                    
                                    c_iguais = c_iguais + 1
                                    Lista_entity_encontrada_PubTator[c_iguais] = termo
                                    Lista_entity_BD[c_iguais] = termo_DB
                                    Lista_entity_e_BD[c_iguais] = termo_DB
                                    Lista_entity_ID[c_iguais] = df_terms_hgnc$hgnc_id[x]
                                    Lista_entity_mesh_id[c_iguais] = HGNC_ID
                                    Lista_entity_start_pos[c_iguais] = pos1
                                    Lista_entity_end_pos[c_iguais] = pos2
                                    Lista_entity_type[c_iguais] = "gene_hgnc_entity"
                                    Lista_entity_PMID[c_iguais] = PMID
                                    break()
                                  }
                                }
                              }
                          }else if((tolower(termo) %in% df_terms_genes_equivalence$equivalence_term) | (tolower(termo) %in% df_terms_genes_equivalence$equivalence_term2)){
       
                            for(y in 1:nrow(df_terms_genes_equivalence)){
                              if((tolower(termo) == df_terms_genes_equivalence$equivalence_term[y]) | (tolower(termo) == df_terms_genes_equivalence$equivalence_term2[y])){
                                cat('\n #########################')
                                size = pos2 - pos1 
                                termo_troca <- format("G&N", width = size, justify = "c")
                                substr(texto, pos1, pos2) <- termo_troca
                                
                                c_iguais = c_iguais + 1
                                Lista_entity_encontrada_PubTator[c_iguais] = termo
                                Lista_entity_BD[c_iguais] = df_terms_genes_equivalence$equivalence_term[y]
                                Lista_entity_e_BD[c_iguais] = df_terms_genes_equivalence$equivalence_term[y]
                                Lista_entity_ID[c_iguais] = df_terms_genes_equivalence$term_descritor_idterm_descritor[y]
                                Lista_entity_mesh_id[c_iguais] = df_terms_genes_equivalence$idequivalence_relationship[y]
                                Lista_entity_start_pos[c_iguais] = pos1
                                Lista_entity_end_pos[c_iguais] = pos2
                                Lista_entity_type[c_iguais] = "gene_entity"
                                Lista_entity_PMID[c_iguais] = PMID
                                break()
                              }
                            }
                          }
                        }
      
      ##############################################################            
      # Finding for chemical entities about polyphenols using MESH ID  
                }else if(Tipo == 'Chemical'){
                  MeshID = unlist(strsplit(linha[[1]][6], ":"))
                  MeshID = trim(MeshID[2])
                  if(!is.na(MeshID)){
                    PMID = linha[[1]][1]
                    pos1 = as.numeric(linha[[1]][2])
                    pos2 = as.numeric(linha[[1]][3])
                    termo = linha[[1]][4]
                    
                    if(MeshID %in% df_terms_chemical_equivalence$MeshID){
                      for(x in 1:nrow(df_terms_chemical_equivalence)){
                        MeshID_DB = trim(df_terms_chemical_equivalence$MeshID[x])
                        termo_DB = trim(df_terms_chemical_equivalence$Name[x])
                        if(!is.na(MeshID_DB)){
                          if(MeshID == MeshID_DB){
                            cat('\n #########################')
                            
                            size = pos2 - pos1 
                            termo_troca <- format("CH&", width = size, justify = "c")
                            substr(texto, pos1, pos2) <- termo_troca
                            
                            c_iguais = c_iguais + 1
                            Lista_entity_encontrada_PubTator[c_iguais] = termo
                            Lista_entity_BD[c_iguais] = termo_DB
                            Lista_entity_e_BD[c_iguais] = termo_DB
                            Lista_entity_ID[c_iguais] = df_terms_chemical_equivalence$idterm_descritor[x]
                            Lista_entity_mesh_id[c_iguais] = MeshID_DB
                            Lista_entity_start_pos[c_iguais] = pos1
                            Lista_entity_end_pos[c_iguais] = pos2
                            Lista_entity_type[c_iguais] = "chemical_entity_p"
                            Lista_entity_PMID[c_iguais] = PMID
                            break()
                          }
                        }
                      }
                    }else if((tolower(termo) %in% df_terms_chemical_equivalence$equivalence_term) | (tolower(termo) %in% df_terms_chemical_equivalence$equivalence_term2)){
                      for(y in 1:nrow(df_terms_chemical_equivalence)){
                        if((tolower(termo) == df_terms_chemical_equivalence$equivalence_term[y]) | (tolower(termo) == df_terms_chemical_equivalence$equivalence_term2[y])){
                          cat('\n #########################')
                          size = pos2 - pos1 
                          termo_troca <- format("CH&", width = size, justify = "c")
                          substr(texto, pos1, pos2) <- termo_troca
                          
                          c_iguais = c_iguais + 1
                          Lista_entity_encontrada_PubTator[c_iguais] = termo
                          Lista_entity_BD[c_iguais] = df_terms_chemical_equivalence$Name[y]
                          Lista_entity_e_BD[c_iguais] = df_terms_chemical_equivalence$equivalence_term[y]
                          Lista_entity_ID[c_iguais] = df_terms_chemical_equivalence$idterm_descritor[y]
                          Lista_entity_mesh_id[c_iguais] = df_terms_chemical_equivalence$MeshID[y]
                          Lista_entity_start_pos[c_iguais] = pos1
                          Lista_entity_end_pos[c_iguais] = pos2
                          Lista_entity_type[c_iguais] = "chemical_entity_e"
                          Lista_entity_PMID[c_iguais] = PMID
                          break()
                        }
                      }
                    }
                  }
                }
          
          }
        }
  cat('\n ################################################## CONTADOR = ',z)
  
  #Selecting sentences with polyphenol-cancer or polyphenol-gene associations
  if(((grepl('D&S', texto)) & (grepl('CH&', texto))) | ((grepl('G&N', texto)) & (grepl('CH&', texto)))) {
      
     #Transforming and preparing sentences
      texto_original = gsub('264.7','264_7',texto_original)
      texto = gsub('0.05','0_05',texto)
      texto_original = gsub('0.05','0_05',texto_original)
      texto = gsub('0.01','0_01',texto)
      texto_original = gsub('0.01','0_01',texto_original)
      texto = gsub('0.001','0_001',texto)
      texto_original = gsub('0.001','0_001',texto_original)
      texto_original = gsub('[\\|]','/',texto_original)
      sentences_original = sent_detect(texto_original, rm.bracket = FALSE)
      texto_original = gsub('[\\,]','_',texto_original)
      sentences2 = sent_detect(texto, rm.bracket = FALSE)
      sentences3 = sent_detect(texto_original, rm.bracket = FALSE)
      sentences3 = gsub('[*]','_', sentences3)
      sentences2 = gsub('[*]','_', sentences2)
      sentences3 = gsub('[**]','__', sentences3)
      sentences2 = gsub('[**]','__', sentences2)
      sentences3 = gsub('[***]','___', sentences3)
      sentences2 = gsub('[***]','___', sentences2)
      sentences3 = gsub('[+]','_', sentences3)
      sentences2 = gsub('[+]','_', sentences2)
      sentences2 = gsub('[\\[]','_', sentences2)
      sentences2 = gsub('[\\]]','_', sentences2)
      sentences3 = gsub('[\\[]','_', sentences3)
      sentences3 = gsub('[\\]]','_', sentences3)
      sentences2 = gsub('[\\{]','_', sentences2)
      sentences2 = gsub('[\\}]','_', sentences2)
      sentences3 = gsub('[\\{]','_', sentences3)
      sentences3 = gsub('[\\}]','_', sentences3)
      
      if(length(sentences2) == length(sentences3)){
      
          for(x in 1:length(sentences2)){
            #Selecting sentences with more than 6 words and 40 characters
            sentence_size = nchar(sentences3[x])
            if((sapply(strsplit(sentences2[x], " "), length) > 6) & (sentence_size > 40)){
                if((grepl('G&N', sentences2[x])) & (grepl('D&S', sentences2[x])) & (grepl('CH&', sentences2[x]))) {
                  d = d + 1
                  cat("\n Sentence tripla: ",sentences2[x])
                  lst_pmids[d] = PMID  
                  lst_sentences_2[d] = sentences2[x] 
                  lst_sentences_3[d] = sentences3[x]
                  lst_orinal_sentences[d] = sentences_original[x]
                  lst_association[d] = "sim3"
                  lst_entitie[d] = "sim"
                  if((grepl(reg_expression_conclusion, sentences3[x])) | (x > (length(sentences2) - 3))){
                    lst_conclusion[d] = "sim"
                  }else{
                    lst_conclusion[d] = "nao"
                  }
                  if(x == 1){
                    lst_title[d] = "sim"
                  }else{
                    lst_title[d] = "nao"
                  }
                  pattern_sentence = substr(sentences3[x],1,50)
                  pattern_sentence = gsub('[\\(]','\\\\(',pattern_sentence)
                  pattern_sentence = gsub('[)]','\\\\)',pattern_sentence)
                  start_pos = unlist(gregexpr(pattern = pattern_sentence, texto_original))
                  end_pos = start_pos + sentence_size
                  cat("\n Start pos: ",start_pos)
                  cat("\n End pos: ",end_pos)
                  lst_start_pos[d] = start_pos
                  lst_end_pos[d] = end_pos
                  
                }else{
                  if(((grepl('D&S', sentences2[x])) & (grepl('CH&', sentences2[x]))) | ((grepl('G&N', sentences2[x])) & (grepl('CH&', sentences2[x]))) | ((grepl('G&N', sentences2[x])) & (grepl('D&S', sentences2[x])))){
                    d = d + 1
                    cat("\n Sentence dupla: ",sentences2[x])
                    lst_pmids[d] = PMID  
                    lst_sentences_2[d] = sentences2[x] 
                    lst_sentences_3[d] = sentences3[x]
                    lst_orinal_sentences[d] = sentences_original[x]
                    lst_association[d] = "sim"
                    lst_entitie[d] = "sim"
                    if((grepl(reg_expression_conclusion, sentences3[x])) | (x > (length(sentences2) - 3))){
                      lst_conclusion[d] = "sim"
                    }else{
                      lst_conclusion[d] = "nao"
                    }
                    if(x == 1){
                      lst_title[d] = "sim"
                    }else{
                      lst_title[d] = "nao"
                    }
                    pattern_sentence = substr(sentences3[x],1,50)
                    pattern_sentence = gsub('[\\(]','\\\\(',pattern_sentence)
                    pattern_sentence = gsub('[)]','\\\\)',pattern_sentence)
                    start_pos = unlist(gregexpr(pattern = pattern_sentence, texto_original))
                    end_pos = start_pos + sentence_size
                    cat("\n Start pos: ",start_pos)
                    cat("\n End pos: ",end_pos)
                    lst_start_pos[d] = start_pos
                    lst_end_pos[d] = end_pos
                    
                  }else{
                    d = d + 1
                    cat("\n Sentence: ",sentences2[x])
                    lst_pmids[d] = PMID  
                    lst_sentences_2[d] = sentences2[x] 
                    lst_sentences_3[d] = sentences3[x]
                    lst_orinal_sentences[d] = sentences_original[x]
                    lst_association[d] = "nao"
                    if((grepl('G&N', sentences2[x])) | (grepl('D&S', sentences2[x])) | (grepl('CH&', sentences2[x]))) {
                      lst_entitie[d] = "sim"
                    }else{
                      lst_entitie[d] = "nao"
                    }
                    if((grepl(reg_expression_conclusion, sentences3[x])) | (x > (length(sentences3) - 2))){
                      lst_conclusion[d] = "sim"
                    }else{
                      lst_conclusion[d] = "nao"
                    }
                    if(x == 1){
                      lst_title[d] = "sim"
                    }else{
                      lst_title[d] = "nao"
                    }
                    pattern_sentence = substr(sentences3[x],1,50)
                    pattern_sentence = gsub('[\\(]','\\\\(',pattern_sentence)
                    pattern_sentence = gsub('[)]','\\\\)',pattern_sentence)
                    start_pos = unlist(gregexpr(pattern = pattern_sentence, texto_original))
                    end_pos = start_pos + sentence_size
                    cat("\n Start pos: ",start_pos)
                    cat("\n End pos: ",end_pos)
                    lst_start_pos[d] = start_pos
                    lst_end_pos[d] = end_pos
                  }
                }
        
            }
          }
      
      }else{
        
        c_articles_diference_sentences = c_articles_diference_sentences + 1
        lst__articles_diference_sentences[c_articles_diference_sentences] = PMID
        
      }
  }
  }
  
}
end_time <- Sys.time()
Tempo = end_time - start_time
cat('\n\n\n Time    = ',Tempo)
  
# Preparing dataframe with pubmed abstracts sentences with  entities associations recognized
lst_pmids = unlist(lst_pmids)
lst_sentences_2 = unlist(lst_sentences_2)
lst_sentences_3 = unlist(lst_sentences_3)
lst_orinal_sentences = unlist(lst_orinal_sentences)
lst_association = unlist(lst_association)
lst_entitie = unlist(lst_entitie)
lst_conclusion = unlist(lst_conclusion)
lst_title = unlist(lst_title)
lst_start_pos = unlist(lst_start_pos)
lst_end_pos = unlist(lst_end_pos)
lst_anotado = list(pmid = lst_pmids, sentence = lst_sentences_2, sentence2 = lst_sentences_3, sentence_original = lst_orinal_sentences, has_entity = lst_entitie, is_association = lst_association, is_conclusion = lst_conclusion, is_title = lst_title, start_pos = lst_start_pos, end_pos = lst_end_pos)
df_anotado = as.data.frame(lst_anotado)
# Preparing dataframe with pubmed abstracts with named entities recognized
Lista_entity_encontrada_PubTator = unlist(Lista_entity_encontrada_PubTator)
Lista_entity_BD = unlist(Lista_entity_BD)
Lista_entity_e_BD = unlist(Lista_entity_e_BD)
Lista_entity_ID = unlist(Lista_entity_ID)
Lista_entity_mesh_id = unlist(Lista_entity_mesh_id)
Lista_entity_start_pos = unlist(Lista_entity_start_pos)
Lista_entity_end_pos = unlist(Lista_entity_end_pos)
Lista_entity_type = unlist(Lista_entity_type)
Lista_entity_PMID = unlist(Lista_entity_PMID)
lst_entities = list(pubtatot_term = Lista_entity_encontrada_PubTator, db_term = Lista_entity_BD, db_equivalence = Lista_entity_e_BD, term_id = Lista_entity_ID, mesh_id = Lista_entity_mesh_id, start_pos = Lista_entity_start_pos, end_pos = Lista_entity_end_pos, entity_type = Lista_entity_type, entity_pmid = Lista_entity_PMID )
df_entities = as.data.frame(lst_entities)
# Preparing dataframe with pubmed abstracts without named entities recognized
lst__articles_diference_sentences = unlist(lst__articles_diference_sentences)
df_articles_nao_encontrados = list(pmid = lst__articles_diference_sentences)
df_articles_nao_encontrados = as.data.frame(df_articles_nao_encontrados)

# Final dataframe with pubmed abstracts sentences with  entities associations recognized
View(df_anotado)
# Final dataframe with pubmed abstracts with named entities recognized
View(df_entities)
# Final dataframe with pubmed abstracts without named entities recognized
View(df_articles_nao_encontrados)


