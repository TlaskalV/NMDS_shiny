# NMDS shiny
App for fast NMDS plots of sample sites based on microbial OTUs relative abundance.

<img align="right" src="/pictures/nmds.png?raw=true" width="400">

## Table of contents

* [Where to try app](#where-to-try-app)
* [How to upload data](#data-upload)
* [Settings](#settings)

## Where to try app
* <img align="left" src="/pictures/shiny_logo.png?raw=true" width="50"> online web app hosted on [labenvmicro.shinyapps.io](https://labenvmicro.shinyapps.io/shiny_nmds/), this option is limited to 1GB of RAM memory. Therefore bigger data may take some time to analyze. For huge tables beyond memory limit the online app gives error.  




* <img align="left" src="/pictures/r_logo.png?raw=true" width="50"> or start your local installation of **R** language and paste following code which automatically downloads prerequisties and starts app. Better option for big data, the only limit is local computer hardware:
```
install.packages(c("shiny", "shinythemes", "openxlsx", "tidyverse", "vegan", "shinycssloaders", "ggrepel"))
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


<div align="left">
    <img src="/pictures/upload_otu_table.png?raw=true" width="400px"</img> 
</div>


2. **Sample list** ([example](https://github.com/Vojczech/NMDS_shiny/blob/master/samples.xlsx)) with sample names (same names as in OTU table) and further environmental variables which are used for grouping in NMDS and `envfit` function. Again, choose sheet by its name.

| sample_name | age_class |sampled_org | year | 
|:---------:|:-------:|:------:|:-------:| 
|    sample1     |  1     |    fagus  |    2013  | 
|  sample2   |  2   |   fagus  | 2008     | 
|    sample3     |   1    |  picea   |     2013   | 
|    sample4     |   2    |  spruce   |     2008   | 
|    sample5     |   3    |  spruce   |     1997   | 

<div align="left">
    <img src="/pictures/upload_sample_list.png?raw=true" width="400px"</img> 
</div>


You should now see the preview of the uploaded tables.
<div align="left">
    <img src="/pictures/upload_preview.png?raw=true" width="400px"</img> 
</div>


## Settings 

1. After upload of the tables (.xlsx) it is necessary to choose the correct excel sheet by its name.
<div align="left">
    <img src="/pictures/upload.png?raw=true" width="400px"</img> 
</div>

***

2. It is possible to filter OTUs for NMDS construction by abundance treshold in certain number of samples.
<div align="left">
    <img src="/pictures/settings_filter.png?raw=true" width="400px"</img> 
</div>

***

3. Colours of points in NMDS

* For colour coding of different groups of samples choose appropriate grouping factor (i.e. column with environmental variable in the sample list) and check "Factor". By checking **Display ellipses** ggplot will calculate ellipses for each group of points.

or

* For gradient colour of sample sites according to environmental metadata choose "Values".
<div align="left">
    <img src="/pictures/settings.png?raw=true" width="300px"</img> 
</div>

***

4. Label points by sample ID or sample type or by other variable. Label positions are iteratively found with great package [`ggrepel`](https://github.com/slowkow/ggrepel) by [@slowkow](https://github.com/slowkow).
<div align="left">
    <img src="/pictures/settings_labels.png?raw=true" width="400px"</img> 
</div>

***

5. Hellinger distance or Bray-Curtis dissimilarity are two optional [dissimilarity measures](https://mb3is.megx.net/gustame/reference/dissimilarity) which can be used. Default is Hellinger distance based on <cite>[Legendre, 2013][1]</cite>.
<div align="left">
    <img src="/pictures/dismatrix.png?raw=true" width="300px"</img> 
</div>

***

6. By selecting columns from your sample list, you can fit several environmental variables into NMDS using `envfit` function. **Avoid missing values in environmental variables**
<div align="left">
    <img src="/pictures/envfit.png?raw=true" width="300px"</img> 
</div>

***

7. You can download 
* Excel file with NMDS points coordinates and environmental variables scores. This is useful if you want to plot ordination in external program. 

* final pdf file with rendered ggplot
<div align="left">
    <img src="/pictures/nmds.png?raw=true" width="500px"</img> 
</div>

***

> Memory on the [shinyapps.io](https://labenvmicro.shinyapps.io/shiny_nmds/) is limited, if server disconnects after upload try to reduce excel file size by deleting of unnecessary OTUs (singletons and rare ones) or use your own local R installation as described in [Where to try app](https://github.com/Vojczech/NMDS_shiny#where-to-try-app)
</div>

[1]Legendre P, De Cáceres M. Beta diversity as the variance of community data: Dissimilarity coefficients and partitioning. Ecol Lett 2013;16:951–63.
