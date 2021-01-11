##################################################################################################
# Associations Recognition in pubmed abstracts with entities recognized
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
# Retrieving datafames with named entity and entities associations recognized in NER step
setwd("/project-folder/entities-associations-sentences-recognized/")
df_anotado_sentences01_2000 = read.table(file = 'df_anotado_sentences01_2000.tsv', sep = '\t')
df_anotado_sentences2001_5000 = read.table(file = 'df_anotado_sentences2001_5000.tsv', sep = '\t')
df_anotado_sentences5001_8000 = read.table(file = 'df_anotado_sentences5001_8000.tsv', sep = '\t')
df_anotado_sentences8001_9000 = read.table(file = 'df_anotado_sentences8001_9000.tsv', sep = '\t')
df_anotado_sentences9001_10000 = read.table(file = 'df_anotado_sentences9001_10000.tsv', sep = '\t')
df_anotado_sentences10001_11000 = read.table(file = 'df_anotado_sentences10001_11000.tsv', sep = '\t')
df_anotado_sentences11001_14000 = read.table(file = 'df_anotado_sentences11001_14000.tsv', sep = '\t')
df_anotado_sentences14001_15000 = read.table(file = 'df_anotado_sentences14001_15000.tsv', sep = '\t')
df_anotado_sentences15001_16000 = read.table(file = 'df_anotado_sentences15001_16000.tsv', sep = '\t')
df_anotado_sentences16001_17000 = read.table(file = 'df_anotado_sentences16001_17000.tsv', sep = '\t')
df_anotado_sentences17001_18000 = read.table(file = 'df_anotado_sentences17001_18000.tsv', sep = '\t')
df_anotado_sentences18001_21000 = read.table(file = 'df_anotado_sentences18001_21000.tsv', sep = '\t')
df_anotado_sentences21001_23000 = read.table(file = 'df_anotado_sentences21001_23000.tsv', sep = '\t')
df_anotado_sentences23001_26000 = read.table(file = 'df_anotado_sentences23001_26000.tsv', sep = '\t')
df_anotado_sentences_n_encontradas = read.table(file = 'df_anotado_sentences_n_encontradas.tsv', sep = '\t')
df_anotado_sentences_total = rbind(df_anotado_sentences01_2000,df_anotado_sentences2001_5000,df_anotado_sentences5001_8000,df_anotado_sentences8001_9000,df_anotado_sentences9001_10000,df_anotado_sentences10001_11000,df_anotado_sentences11001_14000,df_anotado_sentences14001_15000,df_anotado_sentences15001_16000,df_anotado_sentences16001_17000,df_anotado_sentences17001_18000,df_anotado_sentences18001_21000,df_anotado_sentences21001_23000,df_anotado_sentences23001_26000,df_anotado_sentences_n_encontradas)
setwd("/project-folder/entities-recognized/")
df_entities01_2000 = fread(file = 'df_entities01_2000.tsv')
df_entities2001_5000 = fread(file = 'df_entities2001_5000.tsv')
df_entities5001_8000 = fread(file = 'df_entities5001_8000.tsv')
df_entities8001_9000 = fread(file = 'df_entities8001_9000.tsv')
df_entities9001_10000 = fread(file = 'df_entities9001_10000.tsv')
df_entities10001_11000 = fread(file = 'df_entities10001_11000.tsv')
df_entities11001_14000 = fread(file = 'df_entities11001_14000.tsv')
df_entities14001_15000 = fread(file = 'df_entities14001_15000.tsv')
df_entities15001_16000 = fread(file = 'df_entities15001_16000.tsv')
df_entities16001_17000 = fread(file = 'df_entities16001_17000.tsv')
df_entities17001_18000 = fread(file = 'df_entities17001_18000.tsv')
df_entities18001_21000 = fread(file = 'df_entities18001_21000.tsv')
df_entities21001_23000 = fread(file = 'df_entities21001_23000.tsv')
df_entities23001_26000 = fread(file = 'df_entities23001_26000.tsv')
df_entities_n_encontradas = fread(file = 'df_entities_n_encontradas.tsv')
df_entities_total = rbind(df_entities01_2000,df_entities2001_5000,df_entities5001_8000,df_entities8001_9000,df_entities9001_10000,df_entities10001_11000,df_entities11001_14000,df_entities14001_15000,df_entities15001_16000,df_entities16001_17000,df_entities17001_18000,df_entities18001_21000,df_entities21001_23000,df_entities23001_26000,df_entities_n_encontradas)


###########################################################################################
# Transforming dataframes to ajust positions in pubmed abstracts sentences 
df_anotado_sentences = df_anotado_sentences_total
df_anotado_sentences$sentence = as.character(df_anotado_sentences$sentence)
df_anotado_sentences$is_title = as.character(df_anotado_sentences$is_title)
c = 0
for(i in 1:nrow(df_anotado_sentences)){
  if(df_anotado_sentences$start_pos[i] == -1){
    c = c + 1
    cat('\n\n\n Contador    = ',c)
    cat('\n Pos    = ',df_anotado_sentences$start_pos[i])
    cat('\n Sen    = ',df_anotado_sentences$sentence[i])
    cat('\n PMID    = ',df_anotado_sentences$pmid[i])
    if(df_anotado_sentences$is_title[i] == 'nao'){
      end_pos_prev = df_anotado_sentences$end_pos[i-1]
      cat('\n\n Pos prev    = ',end_pos_prev)
      start_pos_new = end_pos_prev + 1
      end_pos_new = start_pos_new + df_anotado_sentences$end_pos[i]
      cat('\n Start pos new    = ',start_pos_new)
      cat('\n End pos new    = ',end_pos_new)
      df_anotado_sentences$start_pos[i] = start_pos_new
      df_anotado_sentences$end_pos[i] = end_pos_new
    }else{
      start_pos_new = 1
      end_pos_new = df_anotado_sentences$end_pos[i]
      cat('\n Start pos new    = ',start_pos_new)
      cat('\n End pos new    = ',end_pos_new)
      df_anotado_sentences$start_pos[i] = start_pos_new
      df_anotado_sentences$end_pos[i] = end_pos_new
    }
  }
}
for(i in 1:nrow(df_entities_total)){
  
  if(df_entities_total$start_pos[i] == 0){
    df_entities_total$start_pos[i] = 1
  }
  
}


###########################################################################################
# Pre-processing of pubmed abstracts sentences 
df_anotado_sentences$sentence_original = as.character(df_anotado_sentences$sentence_original)
df_anotado_sentences$sentence = as.character(df_anotado_sentences$sentence)
df_anotado_sentences$sentence_id = str_c(df_anotado_sentences$pmid, df_anotado_sentences$start_pos)
df_anotado_sentences$has_entity = as.character(df_anotado_sentences$has_entity)
df_anotado_sentences$is_association = as.character(df_anotado_sentences$is_association)
df_anotado_sentences$is_title = as.character(df_anotado_sentences$is_title)


###########################################################################################
# Associations recognition in pubmed abstracts sentences using regular expressions from rules dictionary
start_time = Sys.time()
erro = 0
c = 0
encontrado = 0
encontrado2 = 0
encontrado3 = 0
c_passiva = 0
c_passiva2 = 0
lst_encontrados = list()
lst_pmid = list()
lst_encontrados_ori = list()
lst_id_sentence = list()
lst_tipo_reg_expression = list() 
lst_polifenol = list()
lst_cancer = list()
lst_R1 = list()
lst_R2 = list()
lst_R3 = list()
lst_R4 = list()
lst_R5 = list()
lst_R6 = list()
lst_R7 = list()
lst_R8 = list()
lst_R9 = list()
lst_R10 = list()
lst_R11 = list()
lst_R12 = list()
lst_R13 = list()
lst_R14 = list()
lst_R15 = list() 
lst_R16 = list()
lst_is_title = list()
lst_has_entity = list()
lst_is_association = list()
lst_start_pos = list()
lst_end_pos = list()
lst_HM12 = list()
lst_HM3 = list()
lst_HM4 = list()
lst_HM5 = list()
lst_HM6 = list()
lst_HM7 = list()
lst_HM8 = list()
lst_HM9 = list()
lst_HM10 = list()

for(x in 1:nrow(df_anotado_sentences)){
  # Regular expressions from rule dictionary
  reg_expression1 = '(inhibits|inhibited|inhibit|blocks|blocked|suppress|suppressed|suppresses|attenuate|attenuated|attenuates|reduce|reduces|reduced|prevent|prevents|prevented)[\\w]*'
  reg_expression2 = '(inhibit|inhibits|inhibited|suppress|suppresses|suppressed|reduce|reduced)[\\w]*(.*)(invasion|growth|migration|angiogenesis|metastasis|viability|proliferation|cancer|carcinogenese|cells|cell line|tumor|tumour|neoplasm)[\\w]*'
  reg_expression3 = '(protective|activity|activities|effects|agent|protect|potent|effective|promising|cytotoxicity|cytotoxic|chemopreventive|anticancer|anti-cancer|antitumor|anti-tumor|antiproliferative|anti-proliferative|inhibitory)[\\w]*(.*)(against)[\\w]*'
  reg_expression4 = '(cause|causes|caused|result|resulted|results|mediates|mediated|induces|induces|induced|enhance|enhanced|modulate|modulated|modulates|mediates|mediated|promote|promoted)[\\w]*(.*)(inhibition|reduction|death|arrest|apoptosis|autophagy|suppression)[\\w]*(.*)(of|on|in)[\\w]*(.*)(cancer|cell|neoplasm|malignancy|tumor|tumour|malignant)[\\w]*'
  reg_expression51 = '(inhibition|suppression|reduction|inhibited|mediated|reduced|suppressed|blocked)[\\w]*(.*)(of|in|on)[\\w]*(.*)(invasion|growth|migration|angiogenesis|metastasis|viability|proliferation|cancer|carcinogenese|cells|cell line|tumor|tumour|neoplasm)[\\w]*'
  reg_expression52 = '(invasion|growth|migration|angiogenesis|metastasis|viability|proliferation|cancer|carcinogenese|cells|cell line|tumor|tumour|neoplasm)[\\w]*(.*)(inhibition|suppression|reduction|inhibited|mediated|reduced|suppressed|blocked)[\\w]*'
  reg_expression61 = '(anti)[\\w]*(.*)(cancer|tumor|tumour|neoplastic|carcinogenic|angiogenic|angiogenesis|tumorigenic|metastatic|metastasis|proliferative|oxidant|invasive|migration)[\\w]*(.*)(effect|activity|activities|agent|propertie|properties|potential)[\\w]*'
  reg_expression62 = '(effect|activity|activities|agent|propertie|properties|potential)[\\w]*(.*)(anti)[\\w]*(.*)(cancer|tumor|tumour|neoplastic|carcinogenic|angiogenic|angiogenesis|tumorigenic|metastatic|metastasis|proliferative|oxidant|invasive|migration)[\\w]*'
  reg_expression63 = '(anticancer|anti-cancer|anti-tumor|antitumor|anti-fumour|antitumour|anticarcinogenic|anti-carcinogenic|antineoplastic|anti-neoplastic|antiangiogenic|anti-angiogenic|antiangiogenesis|anti-angiogenesis|antimetastatic|anti-metastatic|antimetastasis|anti-metastasis|antiinvasive|anti-invasive|antiproliferative|anti-proliferative|antioxidant|anti-oxidant|antitumor|anti-tumor|proapoptotic|pro-apoptotic|pro apoptotic|anti-tumorigenic|antitumorigenic|inhibitory|cytotoxicity|cytotoxic|chemopreventive|promising|protective|therapeutic|chemotherapeutic|chemotherapy|preventive|treatment|therapy|therapies|radiotherapy|immunotherapy|prognosis|prognostic)[\\w]*(.*)(effect|activity|activities|agent|propertie|properties|potential)[\\w]*'
  reg_expression64 = '(effect|activity|activities|agent|propertie|properties|potential)[\\w]*(.*)(anticancer|anti-cancer|anti-tumor|antitumor|anti-fumour|antitumour|anticarcinogenic|anti-carcinogenic|antineoplastic|anti-neoplastic|antiangiogenic|anti-angiogenic|antiangiogenesis|anti-angiogenesis|antimetastatic|anti-metastatic|antimetastasis|anti-metastasis|antiinvasive|anti-invasive|antiproliferative|anti-proliferative|antioxidant|anti-oxidant|antitumor|anti-tumor|proapoptotic|pro-apoptotic|pro apoptotic|anti-tumorigenic|antitumorigenic|inhibitory|cytotoxicity|cytotoxic|chemopreventive|promising|protective|therapeutic|chemotherapeutic|chemotherapy|preventive|treatment|therapy|therapies|radiotherapy|immunotherapy|prognosis|prognostic)[\\w]*'
  reg_expression7 = '(exhibit|exhibited|exhibits|shown|demonstrated|present|has|have|enhanced|enhances|reported|possesses)[\\w]*(.*)(effect|activity|activities|potent|propertie|properties|potential|cytotoxicity|cytotoxic|inhibitory)[\\w]*'
  reg_expression8 = '(inhibition|reduction|death|arrest|apoptosis|autophagy|suppression)[\\w]*(.*)(caused|resulted|mediated|induced|enhanced|promoted)[\\w]*(.*)(by)[\\w]*'
  reg_expression9 = '(activity|viability|invasion|growth|migration|angiogenesis|metastasis|viability|proliferation|cancer|carcinogenese|cells|cell line|tumor|tumour|neoplasm)[\\w]*(.*)(inhibited|mediated|reduced|suppressed|blocked)[\\w]*(.*)(by)[\\w]*'
  reg_expression10 = '(inhibition|reduction|death|arrest|apoptosis|autophagy|suppression|migration|metastasis|viability|proliferation)[\\w]*(.*)(of)[\\w]*(.*)(by)[\\w]*'
  reg_expression11 = '(disruption|regulation|abolished|repressed|stimulated|regulate|regulated|regulates|downregulate|downregulates|downregulated|upregulate|upregulated|upregulates|down-regulate|down-regulates|down-regulated|up-regulate|up-regulated|up-regulates| down regulate|down regulates|down regulated|up regulate|up regulated|up regulates|reduce|reduced|reduces|block|blocks|blocked|increase|increases|increased|decreases|decreased|decrease|induce|induced|induces|inhibit|inhibited|inhibits|suppress|suppressed|suppresses|enhanced|attenuated|active|activation)[\\w]*'
  reg_expression121 = '(induction|inhibition|regulation|abolished|repressed|stimulated|regulate|regulated|regulates|downregulate|downregulates|downregulated|upregulate|upregulated|upregulates|down-regulate|down-regulates|down-regulated|up-regulate|up-regulated|up-regulates| down regulate|down regulates|down regulated|up regulate|up regulated|up regulates|reduce|reduced|reduces|block|blocks|blocked|increase|increases|increased|decreases|decreased|decrease|induce|induced|induces|inhibit|inhibited|inhibits|suppress|suppressed|suppresses|enhanced|attenuated|active|activation|disruption)[\\w]*(.*)(expression|levels|activation|via|pathway|protein|signaling|kinase|gene|mrna|mirna|microrna|activity)[\\w]*'
  reg_expression122 = '(expression|levels|activation|via|pathway|protein|signaling|kinase|gene|mrna|mirna|microrna|activity)[\\w]*(.*)(induction|inhibition|regulation|abolished|repressed|stimulated|regulate|regulated|regulates|downregulate|downregulates|downregulated|upregulate|upregulated|upregulates|down-regulate|down-regulates|down-regulated|up-regulate|up-regulated|up-regulates| down regulate|down regulates|down regulated|up regulate|up regulated|up regulates|reduce|reduced|reduces|block|blocks|blocked|increase|increases|increased|decreases|decreased|decrease|induce|induced|induces|inhibit|inhibited|inhibits|suppress|suppressed|suppresses|enhanced|attenuated|activation|disruption)[\\w]*'
  reg_expression13 = '(epigenetic|histone|methylation|methylated|mirna|microrna|mi-rna|phosphorylated|phosphorylation|acetylated|acetylation|acetylase)[\\w]*'
  reg_expression14 = '(novel|new|protective|potent|effective|promising)[\\w]*(.*)(compound|agent|modulators|drug|compost|synthetic|strategy)[\\w]*(.*)(chemopreventive|cells|cell line|tumor cell|anticancer|anti-cancer|anti-tumor|antitumor|anti-fumour|antitumour|anticarcinogenic|anti-carcinogenic|antineoplastic|anti-neoplastic|antiangiogenic|anti-angiogenic|antiangiogenesis|anti-angiogenesis|antimetastatic|anti-metastatic|antimetastasis|anti-metastasis|antiinvasive|anti-invasive|antiproliferative|anti-proliferative|antioxidant|anti-oxidant|antitumor|anti-tumor|proapoptotic|pro-apoptotic|pro apoptotic|anti-tumorigenic|antitumorigenic|inhibitory|cytotoxicity|cytotoxic|chemopreventive|promising|protective|therapeutic|chemotherapeutic|chemotherapy|preventive|treatment|therapy|therapies|radiotherapy|immunotherapy|prognosis|prognostic)[\\w]*'
  reg_expression15 = '(cell line|cells|tumor cell|neoplasm|leukemia|leukaemia|carcinogenesis|tumorigenesis|metastasis|sarcoma|carcinoma|blastoma)[\\w]*'
  reg_expression161 = '(results|our result|findings|conclusion|data|taken|together|study|studies)[\\w]*(.*)(suggest|indicate|suggested|indicated|illustrated|illustrate|revealed|reported|resulted|show)[\\w]*'
  reg_expression162 = '(conclusion)[\\w]*'
  reg_expressionHM11 = '(inhibition|inhibits|inhibited|inhibit|blocks|blocked|suppression|suppress|suppressed|suppresses|attenuate|attenuated|attenuates|reduction|reduce|reduces|reduced|anti)[\\w]*(.*)(proliferation|growth factor|growthfactor|growth-factor|cellgrowth|cell growth|proliferative)[\\w]*'
  reg_expressionHM12 = '(proliferation|growth factor|growthfactor|growth-factor|cellgrowth|cell growth|proliferative)[\\w]*(.*)(inhibition|inhibited|blocked|suppression|suppressed|attenuate|attenuated|attenuates|reduction|reduced)[\\w]*'
  reg_expressionHM31 = '(cause|causes|caused|pro|resulted|induces|induces|induced|enhance|enhanced|modulate|modulated|modulates|mediates|mediated|promote|promoted)[\\w]*(.*)(apoptosis|apoptotic|autophagy|autophagic|necrose|necrosis)[\\w]*'
  reg_expressionHM32 = '(apoptosis|apoptotic|autophagy|autophagic|necrose|necrosis)[\\w]*(.*)(caused|resulted|induced|induction|enhanced|modulated|mediated|promotion|promoted)[\\w]*'
  reg_expressionHM33 = '(cause|causes|caused|pro|resulted|induces|induces|induced|enhance|enhanced|modulate|modulated|modulates|mediates|mediated|promote|promoted)[\\w]*(.*)(cycle|cell)[\\w]*(.*)(arrest|death)[\\w]*'
  reg_expressionHM34 = '(cycle|cell)[\\w]*(.*)(arrest|death)[\\w]*(.*)(caused|resulted|induced|induction|enhanced|modulated|mediated|promotion|promoted)[\\w]*'
  reg_expressionHM4 = '(senescence|telomerase|immortalized)[\\w]*'
  reg_expressionHM51 = '(inhibition|inhibits|inhibited|inhibit|blocks|blocked|suppression|suppress|suppressed|suppresses|attenuate|attenuated|attenuates|reduction|reduce|reduces|reduced|anti)[\\w]*(.*)(angiogenesis|angiogenic)[\\w]*'
  reg_expressionHM52 = '(angiogenesis|angiogenic)[\\w]*(.*)(inhibition|inhibited|blocked|suppression|suppressed|attenuate|attenuated|attenuates|reduction|reduced)[\\w]*'
  reg_expressionHM61 = '(inhibition|inhibits|inhibited|inhibit|blocks|blocked|suppression|suppress|suppressed|suppresses|attenuate|attenuated|attenuates|reduction|reduce|reduces|reduced|anti)[\\w]*(.*)(metastasis|motility|invasion|migration|metastatic|migratory|invasive|invasiveness)[\\w]*'
  reg_expressionHM62 = '(metastasis|motility|invasion|migration|metastatic|migratory|invasive|invasiveness)[\\w]*(.*)(inhibition|inhibited|blocked|suppression|suppressed|attenuate|attenuated|attenuates|reduction|reduced)[\\w]*'
  reg_expressionHM71 = '(mutation|damage|fragmentation)[\\w]*'
  reg_expressionHM72 = '(dna|cell)[\\w]*(.*)(repair|damage|fragmentation)[\\w]*'
  reg_expressionHM81 = '(inhibition|inhibits|inhibited|inhibit|blocks|blocked|suppression|suppress|suppressed|suppresses|attenuate|attenuated|attenuates|reduction|reduce|reduces|reduced|anti)[\\w]*(.*)(inflammation|inflammatory|oxidative|oxidation|oxidant)[\\w]*'
  reg_expressionHM82 = '(inflammation|inflammatory|oxidative|oxidation|oxidant)[\\w]*[\\w]*(.*)(inhibition|inhibited|blocked|suppression|suppressed|attenuate|attenuated|attenuates|reduction|reduced)[\\w]*'
  reg_expressionHM9 = '(metabolism|metabolic|glycolysis|mitochondrial)[\\w]*'
  reg_expressionHM10 = '(immune|immunosuppression)[\\w]*'
  
  ############################################################## 
  # Sentences with polyphenol-cancer associations
  if((grepl('D&S', df_anotado_sentences$sentence[x])) & (grepl('CH&', df_anotado_sentences$sentence[x]))){
    c = c + 1
    pos1 = df_anotado_sentences$start_pos[x]
    pos2 = df_anotado_sentences$end_pos[x]
    entities = df_entities_total[df_entities_total$entity_pmid == df_anotado_sentences$pmid[x],]
    entities_CH = entities[(entities$start_pos >= pos1 & entities$end_pos <= pos2 & ((entities$entity_type == 'chemical_entity_e') | (entities$entity_type == 'chemical_entity_p'))),]
    entities_DS = entities[(entities$start_pos >= pos1 & entities$end_pos <= pos2 & ((entities$entity_type == 'cancer_type_entity_cell') | (entities$entity_type == 'cancer_type_entity_e') | (entities$entity_type == 'cancer_type_entity_p'))),]
    cat('\n Contador    = ',c)
    cat('\n Start Sentence    = ',nrow(entities_CH))
    if((nrow(entities_CH) > 0) & (nrow(entities_DS) > 0)){
      encontrado = encontrado + 1
      lst_encontrados_ori[encontrado] = df_anotado_sentences$sentence_original[x]
      lst_encontrados[encontrado] = df_anotado_sentences$sentence[x]
      lst_pmid[encontrado] = df_anotado_sentences$pmid[x]
      lst_id_sentence[encontrado] = df_anotado_sentences$sentence_id[x]
      lst_tipo_reg_expression[encontrado] = 'polifenol-cancer'
      lst_is_title[encontrado] = df_anotado_sentences$is_title[x]
      lst_has_entity[encontrado] = df_anotado_sentences$has_entity[x]
      lst_is_association[encontrado] = df_anotado_sentences$is_association[x]
      lst_start_pos[encontrado] = df_anotado_sentences$start_pos[x]
      lst_end_pos[encontrado] = df_anotado_sentences$end_pos[x]
      if(grepl(reg_expression1, tolower(df_anotado_sentences$sentence_original[x]))){
         lst_R1[encontrado] = 'sim'
      }else{ 
        lst_R1[encontrado] = 'nao'
        }
      if(grepl(reg_expression2, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_R2[encontrado] = 'sim'
      }else{ 
        lst_R2[encontrado] = 'nao'
      }
      if(grepl(reg_expression3, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_R3[encontrado] = 'sim'
      }else{ 
        lst_R3[encontrado] = 'nao'
      }
      if(grepl(reg_expression4, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_R4[encontrado] = 'sim'
      }else{ 
        lst_R4[encontrado] = 'nao'
      }
      if((grepl(reg_expression51, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression52, tolower(df_anotado_sentences$sentence_original[x])))){
        lst_R5[encontrado] = 'sim'
      }else{ 
        lst_R5[encontrado] = 'nao'
      }
      if((grepl(reg_expression61, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression62, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression63, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression64, tolower(df_anotado_sentences$sentence_original[x])))){
        lst_R6[encontrado] = 'sim'
      }else{ 
        lst_R6[encontrado] = 'nao'
      }
      if(grepl(reg_expression7, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_R7[encontrado] = 'sim'
      }else{ 
        lst_R7[encontrado] = 'nao'
      }
      if(grepl(reg_expression8, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_R8[encontrado] = 'sim'
      }else{ 
        lst_R8[encontrado] = 'nao'
      }
      if(grepl(reg_expression9, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_R9[encontrado] = 'sim'
      }else{ 
        lst_R9[encontrado] = 'nao'
      }
      if(grepl(reg_expression10, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_R10[encontrado] = 'sim'
      }else{ 
        lst_R10[encontrado] = 'nao'
      }
      if(grepl(reg_expression11, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_R11[encontrado] = 'sim'
      }else{ 
        lst_R11[encontrado] = 'nao'
      }
      if((grepl(reg_expression121, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression122, tolower(df_anotado_sentences$sentence_original[x])))){
        lst_R12[encontrado] = 'sim'
      }else{ 
        lst_R12[encontrado] = 'nao'
      }
      if(grepl(reg_expression13, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_R13[encontrado] = 'sim'
      }else{ 
        lst_R13[encontrado] = 'nao'
      }
      if(grepl(reg_expression14, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_R14[encontrado] = 'sim'
      }else{ 
        lst_R14[encontrado] = 'nao'
      }
      if(grepl(reg_expression15, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_R15[encontrado] = 'sim'
      }else{ 
        lst_R15[encontrado] = 'nao'
      }
      if((grepl(reg_expression161, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression162, tolower(df_anotado_sentences$sentence_original[x])))){
        lst_R16[encontrado] = 'sim'
      }else{ 
        lst_R16[encontrado] = 'nao'
      }
      
      if((grepl(reg_expressionHM11, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM12, tolower(df_anotado_sentences$sentence_original[x])))){
        lst_HM12[encontrado] = 'sim'
      }else{ 
        lst_HM12[encontrado] = 'nao'
      }
      if((grepl(reg_expressionHM31, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM32, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM33, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM34, tolower(df_anotado_sentences$sentence_original[x])))){
        lst_HM3[encontrado] = 'sim'
      }else{ 
        lst_HM3[encontrado] = 'nao'
      }
      if(grepl(reg_expressionHM4, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_HM4[encontrado] = 'sim'
      }else{ 
        lst_HM4[encontrado] = 'nao'
      }
      if((grepl(reg_expressionHM51, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM52, tolower(df_anotado_sentences$sentence_original[x])))){
        lst_HM5[encontrado] = 'sim'
      }else{ 
        lst_HM5[encontrado] = 'nao'
      }
      if((grepl(reg_expressionHM61, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM62, tolower(df_anotado_sentences$sentence_original[x])))){
        lst_HM6[encontrado] = 'sim'
      }else{ 
        lst_HM6[encontrado] = 'nao'
      }
      if((grepl(reg_expressionHM71, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM72, tolower(df_anotado_sentences$sentence_original[x])))){
        lst_HM7[encontrado] = 'sim'
      }else{ 
        lst_HM7[encontrado] = 'nao'
      }
      if((grepl(reg_expressionHM81, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM82, tolower(df_anotado_sentences$sentence_original[x])))){
        lst_HM8[encontrado] = 'sim'
      }else{ 
        lst_HM8[encontrado] = 'nao'
      }
      if(grepl(reg_expressionHM9, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_HM9[encontrado] = 'sim'
      }else{ 
        lst_HM9[encontrado] = 'nao'
      }  
      if(grepl(reg_expressionHM10, tolower(df_anotado_sentences$sentence_original[x]))){
        lst_HM10[encontrado] = 'sim'
      }else{ 
        lst_HM10[encontrado] = 'nao'
      } 
    }else{ erro = erro + 1}
  }else{
    ############################################################## 
    # Sentences with polyphenol-gene associations
    if((grepl('G&N', df_anotado_sentences$sentence[x])) & (grepl('CH&', df_anotado_sentences$sentence[x]))){
      c = c + 1
      pos1 = df_anotado_sentences$start_pos[x]
      pos2 = df_anotado_sentences$end_pos[x]
      entities = df_entities_total[df_entities_total$entity_pmid == df_anotado_sentences$pmid[x],]
      entities_CH = entities[(entities$start_pos >= pos1 & entities$end_pos <= pos2 & ((entities$entity_type == 'chemical_entity_e') | (entities$entity_type == 'chemical_entity_p'))),]
      entities_GN = entities[(entities$start_pos >= pos1 & entities$end_pos <= pos2 & ((entities$entity_type == 'gene_entity') | (entities$entity_type == 'gene_hgnc_entity'))),]
      cat('\n Contador    = ',c)
      cat('\n Start Sentence    = ',nrow(entities_CH))
      if((nrow(entities_CH) > 0) & (nrow(entities_GN) > 0)){
        encontrado = encontrado + 1
        lst_encontrados_ori[encontrado] = df_anotado_sentences$sentence_original[x]
        lst_encontrados[encontrado] = df_anotado_sentences$sentence[x]
        lst_pmid[encontrado] = df_anotado_sentences$pmid[x]
        lst_id_sentence[encontrado] = df_anotado_sentences$sentence_id[x]
        lst_tipo_reg_expression[encontrado] = 'polifenol-gene'
        lst_is_title[encontrado] = df_anotado_sentences$is_title[x]
        lst_has_entity[encontrado] = df_anotado_sentences$has_entity[x]
        lst_is_association[encontrado] = df_anotado_sentences$is_association[x]
        lst_start_pos[encontrado] = df_anotado_sentences$start_pos[x]
        lst_end_pos[encontrado] = df_anotado_sentences$end_pos[x]
        lst_R1[encontrado] = 'nao'
        lst_R2[encontrado] = 'nao'
        lst_R3[encontrado] = 'nao'
        lst_R4[encontrado] = 'nao'
        lst_R5[encontrado] = 'nao'
        lst_R6[encontrado] = 'nao'
        lst_R7[encontrado] = 'nao'
        lst_R8[encontrado] = 'nao'
        lst_R9[encontrado] = 'nao'
        lst_R10[encontrado] = 'nao'
        if(grepl(reg_expression11, tolower(df_anotado_sentences$sentence_original[x]))){
          lst_R11[encontrado] = 'sim'
        }else{ 
          lst_R11[encontrado] = 'nao'
        }
        if((grepl(reg_expression121, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression122, tolower(df_anotado_sentences$sentence_original[x])))){
          lst_R12[encontrado] = 'sim'
        }else{ 
          lst_R12[encontrado] = 'nao'
        }
        if(grepl(reg_expression13, tolower(df_anotado_sentences$sentence_original[x]))){
          lst_R13[encontrado] = 'sim'
        }else{ 
          lst_R13[encontrado] = 'nao'
        }
        if(grepl(reg_expression14, tolower(df_anotado_sentences$sentence_original[x]))){
          lst_R14[encontrado] = 'sim'
        }else{ 
          lst_R14[encontrado] = 'nao'
        }
        if(grepl(reg_expression15, tolower(df_anotado_sentences$sentence_original[x]))){
          lst_R15[encontrado] = 'sim'
        }else{ 
          lst_R15[encontrado] = 'nao'
        }
        if((grepl(reg_expression161, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression162, tolower(df_anotado_sentences$sentence_original[x])))){
          lst_R16[encontrado] = 'sim'
        }else{ 
          lst_R16[encontrado] = 'nao'
        }
        if((grepl(reg_expressionHM11, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM12, tolower(df_anotado_sentences$sentence_original[x])))){
          lst_HM12[encontrado] = 'sim'
        }else{ 
          lst_HM12[encontrado] = 'nao'
        }
        if((grepl(reg_expressionHM31, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM32, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM33, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM34, tolower(df_anotado_sentences$sentence_original[x])))){
          lst_HM3[encontrado] = 'sim'
        }else{ 
          lst_HM3[encontrado] = 'nao'
        }
        if(grepl(reg_expressionHM4, tolower(df_anotado_sentences$sentence_original[x]))){
          lst_HM4[encontrado] = 'sim'
        }else{ 
          lst_HM4[encontrado] = 'nao'
        }
        if((grepl(reg_expressionHM51, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM52, tolower(df_anotado_sentences$sentence_original[x])))){
          lst_HM5[encontrado] = 'sim'
        }else{ 
          lst_HM5[encontrado] = 'nao'
        }
        if((grepl(reg_expressionHM61, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM62, tolower(df_anotado_sentences$sentence_original[x])))){
          lst_HM6[encontrado] = 'sim'
        }else{ 
          lst_HM6[encontrado] = 'nao'
        }
        if((grepl(reg_expressionHM71, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM72, tolower(df_anotado_sentences$sentence_original[x])))){
          lst_HM7[encontrado] = 'sim'
        }else{ 
          lst_HM7[encontrado] = 'nao'
        }
        if((grepl(reg_expressionHM81, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM82, tolower(df_anotado_sentences$sentence_original[x])))){
          lst_HM8[encontrado] = 'sim'
        }else{ 
          lst_HM8[encontrado] = 'nao'
        }
        if(grepl(reg_expressionHM9, tolower(df_anotado_sentences$sentence_original[x]))){
          lst_HM9[encontrado] = 'sim'
        }else{ 
          lst_HM9[encontrado] = 'nao'
        }  
        if(grepl(reg_expressionHM10, tolower(df_anotado_sentences$sentence_original[x]))){
          lst_HM10[encontrado] = 'sim'
        }else{ 
          lst_HM10[encontrado] = 'nao'
        } 
      }else{ erro = erro + 1}
    }else{
          ############################################################## 
          # Sentences with polyphenol only
          if(grepl('CH&', df_anotado_sentences$sentence[x])){
            c = c + 1
            pos1 = df_anotado_sentences$start_pos[x]
            pos2 = df_anotado_sentences$end_pos[x]
            entities = df_entities_total[df_entities_total$entity_pmid == df_anotado_sentences$pmid[x],]
            entities_CH = entities[(entities$start_pos >= pos1 & entities$end_pos <= pos2 & ((entities$entity_type == 'chemical_entity_e') | (entities$entity_type == 'chemical_entity_p'))),]
            cat('\n Contador    = ',c)
            cat('\n Start Sentence    = ',nrow(entities_CH))
            if((nrow(entities_CH) > 0)){
              encontrado = encontrado + 1
              lst_encontrados_ori[encontrado] = df_anotado_sentences$sentence_original[x]
              lst_encontrados[encontrado] = df_anotado_sentences$sentence[x]
              lst_pmid[encontrado] = df_anotado_sentences$pmid[x]
              lst_id_sentence[encontrado] = df_anotado_sentences$sentence_id[x]
              lst_tipo_reg_expression[encontrado] = 'polifenol-'
              lst_is_title[encontrado] = df_anotado_sentences$is_title[x]
              lst_has_entity[encontrado] = df_anotado_sentences$has_entity[x]
              lst_is_association[encontrado] = df_anotado_sentences$is_association[x]
              lst_start_pos[encontrado] = df_anotado_sentences$start_pos[x]
              lst_end_pos[encontrado] = df_anotado_sentences$end_pos[x]
              lst_R1[encontrado] = 'nao'
              if(grepl(reg_expression2, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_R2[encontrado] = 'sim'
              }else{ 
                lst_R2[encontrado] = 'nao'
              }
              if(grepl(reg_expression3, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_R3[encontrado] = 'sim'
              }else{ 
                lst_R3[encontrado] = 'nao'
              }
              if(grepl(reg_expression4, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_R4[encontrado] = 'sim'
              }else{ 
                lst_R4[encontrado] = 'nao'
              }
              if((grepl(reg_expression51, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression52, tolower(df_anotado_sentences$sentence_original[x])))){
                lst_R5[encontrado] = 'sim'
              }else{ 
                lst_R5[encontrado] = 'nao'
              }
              if((grepl(reg_expression61, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression62, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression63, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression64, tolower(df_anotado_sentences$sentence_original[x])))){
                lst_R6[encontrado] = 'sim'
              }else{ 
                lst_R6[encontrado] = 'nao'
              }
              lst_R7[encontrado] = 'nao'
              
              if(grepl(reg_expression8, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_R8[encontrado] = 'sim'
              }else{ 
                lst_R8[encontrado] = 'nao'
              }
              if(grepl(reg_expression9, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_R9[encontrado] = 'sim'
              }else{ 
                lst_R9[encontrado] = 'nao'
              }
              if(grepl(reg_expression10, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_R10[encontrado] = 'sim'
              }else{ 
                lst_R10[encontrado] = 'nao'
              }
              lst_R11[encontrado] = 'nao'
              
              if((grepl(reg_expression121, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression122, tolower(df_anotado_sentences$sentence_original[x])))){
                lst_R12[encontrado] = 'sim'
              }else{ 
                lst_R12[encontrado] = 'nao'
              }
              if(grepl(reg_expression13, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_R13[encontrado] = 'sim'
              }else{ 
                lst_R13[encontrado] = 'nao'
              }
              if(grepl(reg_expression14, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_R14[encontrado] = 'sim'
              }else{ 
                lst_R14[encontrado] = 'nao'
              }
              if(grepl(reg_expression15, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_R15[encontrado] = 'sim'
              }else{ 
                lst_R15[encontrado] = 'nao'
              }
              if((grepl(reg_expression161, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expression162, tolower(df_anotado_sentences$sentence_original[x])))){
                lst_R16[encontrado] = 'sim'
              }else{ 
                lst_R16[encontrado] = 'nao'
              }
              
              if((grepl(reg_expressionHM11, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM12, tolower(df_anotado_sentences$sentence_original[x])))){
                lst_HM12[encontrado] = 'sim'
              }else{ 
                lst_HM12[encontrado] = 'nao'
              }
              if((grepl(reg_expressionHM31, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM32, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM33, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM34, tolower(df_anotado_sentences$sentence_original[x])))){
                lst_HM3[encontrado] = 'sim'
              }else{ 
                lst_HM3[encontrado] = 'nao'
              }
              if(grepl(reg_expressionHM4, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_HM4[encontrado] = 'sim'
              }else{ 
                lst_HM4[encontrado] = 'nao'
              }
              if((grepl(reg_expressionHM51, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM52, tolower(df_anotado_sentences$sentence_original[x])))){
                lst_HM5[encontrado] = 'sim'
              }else{ 
                lst_HM5[encontrado] = 'nao'
              }
              if((grepl(reg_expressionHM61, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM62, tolower(df_anotado_sentences$sentence_original[x])))){
                lst_HM6[encontrado] = 'sim'
              }else{ 
                lst_HM6[encontrado] = 'nao'
              }
              if((grepl(reg_expressionHM71, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM72, tolower(df_anotado_sentences$sentence_original[x])))){
                lst_HM7[encontrado] = 'sim'
              }else{ 
                lst_HM7[encontrado] = 'nao'
              }
              if((grepl(reg_expressionHM81, tolower(df_anotado_sentences$sentence_original[x]))) | (grepl(reg_expressionHM82, tolower(df_anotado_sentences$sentence_original[x])))){
                lst_HM8[encontrado] = 'sim'
              }else{ 
                lst_HM8[encontrado] = 'nao'
              }
              if(grepl(reg_expressionHM9, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_HM9[encontrado] = 'sim'
              }else{ 
                lst_HM9[encontrado] = 'nao'
              }  
              if(grepl(reg_expressionHM10, tolower(df_anotado_sentences$sentence_original[x]))){
                lst_HM10[encontrado] = 'sim'
              }else{ 
                lst_HM10[encontrado] = 'nao'
              } 
            }else{ erro = erro + 1}
          }
    }
  }
}
end_time = Sys.time()


############################################################## 
# Preparing final dataframe with pubmed abstracts sentences with at least one rule from rules dictionary recognized 
lst_encontrados_ori = unlist(lst_encontrados_ori)
lst_encontrados = unlist(lst_encontrados)
lst_pmid = unlist(lst_pmid)
lst_id_sentence = unlist(lst_id_sentence)
lst_tipo_reg_expression = unlist(lst_tipo_reg_expression)
df_rules = data.frame(pmid = lst_pmid, sentence_id = lst_id_sentence, association_type = lst_tipo_reg_expression, R1 = unlist(lst_R1), R2 = unlist(lst_R2), R3 = unlist(lst_R3), R4 = unlist(lst_R4), R5 = unlist(lst_R5), R6 = unlist(lst_R6), R7 = unlist(lst_R7), R8 = unlist(lst_R8), R9 = unlist(lst_R9), R10 = unlist(lst_R10), R11 = unlist(lst_R11), R12 = unlist(lst_R12),R13 = unlist(lst_R13), R14 = unlist(lst_R14), R15 = unlist(lst_R15), R16 = unlist(lst_R16), HM12 = unlist(lst_HM12), HM3 = unlist(lst_HM3), HM4 = unlist(lst_HM4), HM5 = unlist(lst_HM5), HM6 = unlist(lst_HM6), HM7 = unlist(lst_HM7), HM8 = unlist(lst_HM8), HM9 = unlist(lst_HM9), HM10 = unlist(lst_HM10), is_title = unlist(lst_is_title), has_entity = unlist(lst_has_entity), is_association = unlist(lst_is_association), start_pos = unlist(lst_start_pos), end_pos = unlist(lst_end_pos), sentence = lst_encontrados, original_sentence = lst_encontrados_ori  , stringsAsFactors = FALSE)
df_rules = unique(df_rules)
# Separating sentences by from entities association type
df_rules_pc = df_rules[df_rules$association_type == 'polifenol-cancer',]
df_rules_pg = df_rules[df_rules$association_type == 'polifenol-gene',]
df_rules_p = df_rules[df_rules$association_type == 'polifenol-',]

# Final dataframe with pubmed abstracts sentences with  at least one rule from rules dictionary recognized 
View(df_rules)






