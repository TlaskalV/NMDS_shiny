# NMDS shiny
App for fast NMDS plots of sample sites based on microbial OTUs relative abundance.

<img align="right" src="/pictures/nmds.png" width="300">

## Table of contents

* [Where to try app](#where-to-try-app)
* [How to upload data](#data-upload)
* [Settings](#settings)

## Where to try app
* <img align="left" src="/pictures/shiny_logo.png" width="50"> online web app hosted on [labenvmicro.shinyapps.io](https://labenvmicro.shinyapps.io/shiny_nmds/), this option is limited to 1GB of RAM memory. Therefore bigger data may take some time to analyze. For huge tables beyond memory limit the online app gives error.  
* <img align="left" src="/pictures/r_logo.png" width="50"> or start your local installation of **R** language and paste following code which automatically downloads prerequisties and starts app. Better option for big data, the only limit is local computer hardware:
```
install.packages(c("shiny", "readxl", "tidyverse", "dplyr", "vegan", "shinycssloaders", "ggrepel"))
library(shiny)
runGitHub("NMDS_shiny", "Vojczech") 
```
## Data upload

**Two excel** files/sheets are necessary:

1. **OTU table** with values in percents. The first column contains OTU label, other columns contanin abundance values in separate samples. After upload of the file, call the correct sheet by its name. 

| OTU_label | sample1 |sample2 | sample3 | sample4 | sample5 | 
|:---------:|:-------:|:------:|:-------:|:-------:|:-------:|
|    CL01     |  1.5     |    5.4  |    10.5  |   8.5  |   7.2  | 
|  CL02   |  2.3    |   4.6  |   9.2   |    2.5  |   9.5  |   1.9  |
|    CL03     |   4.5    |  4.9   |     1.1   |   1.0  |   0.3  |   1.6  |


2. **Sample list** with sample names (same names as in OTU table) and further environmental variables which are used for grouping in NMDS and `envfit` function. Again, choose sheet by its name.

| sample_name | age_class |sampled_org | year | 
|:---------:|:-------:|:------:|:-------:| 
|    sample1     |  1     |    fagus  |    2013  | 
|  sample2   |  2   |   fagus  | 2008     | 
|    sample3     |   1    |  picea   |     2013   | 
|    sample4     |   2    |  spruce   |     2008   | 
|    sample5     |   3    |  spruce   |     1997   | 

---

## Settings 

1. After upload of the tables (.xlsx) it is necessary to choose the correct excel sheet by its name.

2. It is possible to filter OTUs for NMDS construction by abundance treshold in certain number of samples.

3. Colours of points in NMDS

i) For colour coding of different groups of samples choose appropriate grouping factor (i.e. column with environmental variable in the sample list) and check "Factor".

or

ii) For gradient colour of sample sites according to environmental metadata choose "Values".

4. Label points by sample ID or sample type or by other variable

5. [Hellinger transformation](http://mb3is.megx.net/gustame/reference/dissimilarity) as optional approach for lowering influence of rare OTUs.

6. By selecting columns from your sample list, you can fit several environmental variables into NMDS using `envfit` function. **Avoid missing values in environmental variables**

7. It is possible to download .csv tables with NMDS values of each sample site for your own analysis as well as scores for environmental factors.

+ Memory on the shinyapps.io is limited, if server disconnects after upload try to reduce excel file size by deleting of unnecessary OTUs (singletons and rare ones).
 
