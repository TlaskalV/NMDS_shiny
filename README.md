# NMDS shiny
App for fast NMDS plots of sample sites based on microbial OTUs relative abundance.

<img align="right" src="/pictures/nmds.png" width="400">

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

1. **OTU table** ([example](https://github.com/Vojczech/NMDS_shiny/blob/master/otus_percent.xlsx)) with values in percents. The first column contains OTU label, other columns contanin abundance values in separate samples. After upload of the file, call the correct sheet by its name. 

| OTU_label | sample1 |sample2 | sample3 | sample4 | sample5 | 
|:---------:|:-------:|:------:|:-------:|:-------:|:-------:|
|    CL01     |  1.5     |    5.4  |    10.5  |   8.5  |   7.2  | 
|  CL02   |  2.3    |   4.6  |   9.2   |    2.5  |   9.5  |   1.9  |
|    CL03     |   4.5    |  4.9   |     1.1   |   1.0  |   0.3  |   1.6  |


<kbd>
<img align="left" src="/pictures/upload_otu_table.png" width="300">
</kbd>


2. **Sample list** ([example](https://github.com/Vojczech/NMDS_shiny/blob/master/samples.xlsx)) with sample names (same names as in OTU table) and further environmental variables which are used for grouping in NMDS and `envfit` function. Again, choose sheet by its name.

| sample_name | age_class |sampled_org | year | 
|:---------:|:-------:|:------:|:-------:| 
|    sample1     |  1     |    fagus  |    2013  | 
|  sample2   |  2   |   fagus  | 2008     | 
|    sample3     |   1    |  picea   |     2013   | 
|    sample4     |   2    |  spruce   |     2008   | 
|    sample5     |   3    |  spruce   |     1997   | 


<kbd>
<img align="left" src="/pictures/upload_sample_list.png" width="300">
</kbd>


You should now see the preview of the uploaded tables.


<kbd>
<img align="left" src="/pictures/upload_preview.png" width="300">
</kbd>


## Settings 

1. After upload of the tables (.xlsx) it is necessary to choose the correct excel sheet by its name.
<kbd>
<img align="left" src="/pictures/upload.png" width="300">
</kbd>


2. It is possible to filter OTUs for NMDS construction by abundance treshold in certain number of samples.
<kbd>
<img align="left" src="/pictures/settings_filter.png" width="300">
</kbd>


3. Colours of points in NMDS

* For colour coding of different groups of samples choose appropriate grouping factor (i.e. column with environmental variable in the sample list) and check "Factor".

or

* For gradient colour of sample sites according to environmental metadata choose "Values".
<kbd>
<img align="left" src="/pictures/settings.png" width="300">
</kbd>


4. Label points by sample ID or sample type or by other variable. Label positions are iteratively found with great package [`ggrepel`](https://github.com/slowkow/ggrepel) by [@slowkow](https://github.com/slowkow).
<kbd>
<img align="left" src="/pictures/settings_labels.png" width="300">
</kbd>


5. [Hellinger transformation](http://mb3is.megx.net/gustame/reference/dissimilarity) as optional approach for lowering influence of rare OTUs. This is quite common microbial data transformation.


6. By selecting columns from your sample list, you can fit several environmental variables into NMDS using `envfit` function. **Avoid missing values in environmental variables**
<kbd>
<img align="left" src="/pictures/envfit.png" width="300">
</kbd>


7. It is possible to download 
* .csv tables with NMDS values of each sample site for your own analysis

* scores for environmental factors.

* final pdf with rendered ggplot
<div align="left">
    <img src="/pictures/nmds.png" width="400px"</img> 
</div>


> Memory on the [shinyapps.io](https://labenvmicro.shinyapps.io/shiny_nmds/) is limited, if server disconnects after upload try to reduce excel file size by deleting of unnecessary OTUs (singletons and rare ones) or use your own local R installation as described in [Where to try app](https://github.com/Vojczech/NMDS_shiny#where-to-try-app)
