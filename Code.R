#' ---
#' title: "Revenue and Insurance Product Prediction using Census Data"
#' author: "Akshay Kher"
#' date: "April 3, 2019"
#' output: html_document
#' ---
#' 
#' # {.tabset .tabset-fade}
#' 
#' ## Introduction
#' 
#' ### Problem Description
#' 
#' A financial institution wants to analyze the demographic information of the US population to predict:
#' 
#' 1. Revenue earned by the company for a given ZIP code
#' 2. The most popular product sold in a given ZIP code:
#'     * college fund
#'     * retirement fund
#'     * life insurance
#' 
#' ***
#' 
#' ### Data
#' 
#' The sample data given is a portion of the American Community Survey 2015 from census.gov. It contains several fields detailing population, gender, and business metrics grouped by selected ZIP codes throughout the United States. 
#' 
#' 
#' ## Importing Data
#' 
#' ### Libraries Required
## ----warning=FALSE, message=FALSE----------------------------------------
require(Rmisc) # draw multiple plots 
require(readxl) # read excel input
require(DT) # display table on HTML page
require(tidyverse) # perform data manipulation
require(kableExtra)  # display table on HTML page
require(ggplot2) # perform data visualization
require(FNN) # KNN
require(GGally) # plot correlation plots
require(car) # check variance inflation factor
require(nnet) # perform multinomial logistic regression
options(scipen = 999) # do not display numbers in scientific format

#' 
#' ### Reading data 
#' 
#' **Importing Data**
#' 
## ----warnings=FALSE, message=FALSE---------------------------------------
# reading predictor variable data
data <- read_excel("american_fact_finder.xlsx", sheet = "census_train")

# reading response variable data
data_response <- read_excel("american_fact_finder.xlsx", sheet = "response_variable")

# reading id-geographic mapping data
data_mapping <- read_excel("american_fact_finder.xlsx", sheet = "id_geography_mapping")

# renaming predictor variable data
colnames(data) <- c("Id2", 
                    "tot_population",
                    "tot_male_population",
                    "tot_female_population",
                    "perc_male_under_5yrs",
                    "perc_male_45_49yrs",
                    "perc_male_50_54yrs",
                    "perc_male_55_59yrs",
                    "perc_male_5_14yrs",
                    "perc_male_15_44yrs",
                    "perc_male_over_60yrs",
                    "perc_female_under_5yrs",
                    "perc_female_45_49yrs",
                    "perc_female_50_54yrs",
                    "perc_female_55_59yrs",
                    "perc_female_5_14yrs",
                    "perc_female_15_44yrs",
                    "perc_female_over_60yrs",
                    "male_median_age",
                    "female_median_age",
                    "no_establishments",
                    "paid_employees",
                    "payroll_quarter1",
                    "annual_payroll")

# renaming column names of response variable data
colnames(data_response) <- c("geographic_area_name",
                             "revenue",
                             "popular_product")

# renaming column names of id-geographic mapping data
colnames(data_mapping) <- c("Id2",
                             "geographic_area_name")


#' 
#' ***
#' **Data Dictionary**
#' 
#' Predictor Variable Data
## ----echo = FALSE, message = FALSE, warning = FALSE----------------------
text_tbl <- data.frame (
  Variable = names(data),
  Description = c(
    "Unique Zipcode ID",
    "Total Population",
    "Total Male Population", 
    "Total Female Population",
    "Percentage of Males Under 5 Years of Age",
    "Percentage of Males Between 45-49 Years of Age",
    "Percentage of Males Between 50-54 Years of Age",
    "Percentage of Males Between 55-59 Years of Age",
    "Percentage of Males Between 5-14 Years of Age",
    "Percentage of Males Between 15-44 Years of Age",
    "Percentage of Males Over 60 Years of Age",
    "Percentage of Females Under 5 Years of Age",
    "Percentage of Females Between 45-49 Years of Age",
    "Percentage of Females Between 50-54 Years of Age",
    "Percentage of Females Between 55-59 Years of Age",
    "Percentage of Females Between 5-14 Years of Age",
    "Percentage of Females Between 15-44 Years of Age",
    "Percentage of Females Over 60 Years of Age",
    "Median Age of Males in Years",
    "Median Age of Females in Years",
    "Number of Establishments",
    "Paid employees for pay period including March 12 (number)",
    "First-quarter payroll ($1,000)",
    "Annual payroll ($1,000)"
  )
)

kable(text_tbl) %>%
  kable_styling(full_width = F) %>%
  column_spec(1, bold = T, border_right = T) %>%
  column_spec(2, width = "30em")

#' 
#' *** 
#' 
#' Response Variable Data
## ----echo = FALSE, message = FALSE, warning = FALSE----------------------
text_tbl <- data.frame (
  Variable = names(data_response),
  Description = c(
    "Geographic Area Name",
    "Revenue",
    "Popular Product"
  )
)

kable(text_tbl) %>%
  kable_styling(full_width = F) %>%
  column_spec(1, bold = T, border_right = T) %>%
  column_spec(2, width = "30em")

#' 
#' *** 
#' 
#' ID-Geography Mapping Data
## ----echo = FALSE, message = FALSE, warning = FALSE----------------------
text_tbl <- data.frame (
  Variable = names(data_mapping),
  Description = c(
    "Unique Zipcode ID",
    "Geographic Area Name"
  )
)

kable(text_tbl) %>%
  kable_styling(full_width = F) %>%
  column_spec(1, bold = T, border_right = T) %>%
  column_spec(2, width = "30em")

#' 
#' ***
#' **Viewing Data**
#' 
#' Predictor Variable Data
## ------------------------------------------------------------------------
# display first 100 rows
kable(head(data, 100)) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "responsive")) %>%
  scroll_box(width = "100%", height = "500px")

#' 
#' *** 
#' 
#' Response Variable Data
## ------------------------------------------------------------------------
# display first 100 rows
kable(head(data_response, 100)) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "responsive")) %>%
  scroll_box(width = "100%", height = "500px")

#' 
#' *** 
#' 
#' ID-Geography Mapping Data
## ------------------------------------------------------------------------
# display first 100 rows
kable(head(data_mapping, 100)) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "responsive")) %>%
  scroll_box(width = "100%", height = "500px")

#' 
#' ## Data Cleaning and Exploration {.tabset .tabset-fade .tabset-pills}
#' 
#' ### Data Cleaning
#' 
#' **Missing Value Table**
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
# all column indices except ID column
index <- 2:ncol(data)

# convert above columns to numeric
data[index] <- lapply(data[index], as.numeric) 

# calculate missing values
na_table <-
  map_dbl(data, function(x) sum(is.na(x))) %>% 
  sort(decreasing = TRUE) %>% 
  data.frame()

# rename column
colnames(na_table) <- c("total_missing")

# display missing value table
datatable(na_table)

#' 
#' ***
#' 
#' **Removing rows with 8 or more missing columns**
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
 # index for row having 8 or more missing columns
index <- apply(data, 1, function(x) sum(is.na(x)) >= 8) 

# removing above rows
data <- data[!index,]

# calculate missing values
na_table <-
  map_dbl(data, function(x) sum(is.na(x))) %>% 
  sort(decreasing = TRUE) %>% 
  data.frame()

# rename column
colnames(na_table) <- c("total_missing")

# display missing value table
datatable(na_table)

#' 
#' ***
#' 
#' **KNN-Imputation of median ages of males and females**
## ------------------------------------------------------------------------
###### 1. male_median_age ######

# data with output variable and variables on which knn needs to be trained
tr <- na.omit(select(data, tot_population, tot_male_population, 
                      perc_male_under_5yrs:perc_male_over_60yrs, male_median_age))

# data with variables on which knn needs to be trained
tr1 <- select(tr, tot_population, tot_male_population, 
              perc_male_under_5yrs:perc_male_over_60yrs)

# missing data: data on which knn would provide predictions
te1 <- 
  data %>% 
  filter(is.na(male_median_age)) %>% 
    select(tot_population, tot_male_population, 
          perc_male_under_5yrs:perc_male_over_60yrs)
    

# output variable
output_tr <- select(tr, male_median_age)$male_median_age  

# training data for knn without output variable
train <- as.data.frame(tr1) 

# test data to be imputed using knn
test <- as.data.frame(te1)

# output variable
output_var_train <- as.numeric(output_tr)

# perform k-nearest neighbour with k=20
knn_prediction_male <- knn.reg(train=train, test=test, y=output_var_train, k = 20)

# impute missing values with above algorithm
data[is.na(data$male_median_age),]$male_median_age <- knn_prediction_male$pred

###### 2. female_median_age ######

# data with output variable and variables on which knn needs to be trained
tr <- na.omit(select(data, tot_population, tot_female_population, 
                      perc_female_under_5yrs:perc_female_over_60yrs, female_median_age))

# data with variables on which knn needs to be trained
tr1 <- select(tr, tot_population, tot_female_population, 
              perc_female_under_5yrs:perc_female_over_60yrs)

# missing data: data on which knn would provide predictions
te1 <- 
  data %>% 
  filter(is.na(female_median_age)) %>% 
    select(tot_population, tot_female_population, 
          perc_female_under_5yrs:perc_female_over_60yrs)
    

# output variable
output_tr <- select(tr, female_median_age)$female_median_age  

# training data for knn without output variable
train <- as.data.frame(tr1) 

# test data to be imputed using knn
test <- as.data.frame(te1)

# output variable
output_var_train <- as.numeric(output_tr)

# perform k-nearest neighbour with k=20
knn_prediction_female <- knn.reg(train=train, test=test, y=output_var_train, k = 20)

# impute missing values with above algorithm
data[is.na(data$female_median_age),]$female_median_age <- knn_prediction_female$pred

# calculate missing values
na_table <-
  map_dbl(data, function(x) sum(is.na(x))) %>% 
  sort(decreasing = TRUE) %>% 
  data.frame()

# rename column
colnames(na_table) <- c("total_missing")

# display missing value table
datatable(na_table)

#' 
#' ***
#' 
#' **Summary Table**
## ------------------------------------------------------------------------
# summary statistics for numerical variables
summary <- data.frame()
for(i in 2:ncol(data))
{
  name = colnames(data)[i]
  min = min(data[,i], na.rm=TRUE) %>% round(3)
  mean = mean(data[,i,drop=TRUE], na.rm=TRUE) %>% round(3)
  median = median(data[,i,drop=TRUE], na.rm=TRUE) %>% round(3)
  max = max(data[,i], na.rm=TRUE) %>% round(3) %>% round(3)
  count = sum(!is.na(data[,i]))
  df = data.frame(name, min, mean=mean, median=median, max, count)
  summary <- rbind(summary, df)
}

# display summary table
datatable(summary)

#' 
#' ***
#' 
#' **Minimum population greater than equal to 100**
## ------------------------------------------------------------------------
# filtering on population
data <-
  data %>% 
    filter(tot_population >=100)

# summary statistics for numerical variables
summary <- data.frame() 
for(i in 2:ncol(data))
{
  name = colnames(data)[i]
  min = min(data[,i], na.rm=TRUE) %>% round(3)
  mean = mean(data[,i,drop=TRUE], na.rm=TRUE) %>% round(3)
  median = median(data[,i,drop=TRUE], na.rm=TRUE) %>% round(3)
  max = max(data[,i], na.rm=TRUE) %>% round(3) %>% round(3)
  count = sum(!is.na(data[,i]))
  df = data.frame(name, min, mean=mean, median=median, max, count)
  summary <- rbind(summary, df)
}

# display summary table
datatable(summary)

#' 
#' ### Data Exploration
#' 
#' **Joining Response and Predictor Variables**
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
# joining response and predictor variables
data <-
  data %>% 
  left_join(data_mapping, by = "Id2") %>% 
  left_join(data_response, by = "geographic_area_name")

# converting popular product to factor
data$popular_product <- as.factor(data$popular_product)

#' 
#' ***
#' 
#' **Univariate Analysis-I**
#' 
#' Following variables are heavily right-skewed:
#' 
#' * tot_population
#' * tot_male_population
#' * tot_female_population
#' * no_establishments
#' * paid_employees
#' 
#' Following variables are slighly right-skewed:
#' 
#' * payroll_quarter1
#' * annual_payroll
#' * revenue
#' 
#' Following variables are normally distributed:
#' 
#' * male_median_age
#' * female_median_age
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
edaPlot <- function(value, name)
{
  hist <- ggplot(data, aes(x=value)) +
    geom_histogram() +
    ggtitle(name)
  
  hist
}

p1 <- edaPlot(data$tot_population,"tot_population")
p2 <- edaPlot(data$tot_male_population,"tot_male_population")
p3 <- edaPlot(data$tot_female_population,"tot_female_population")
p4 <- edaPlot(data$male_median_age,"male_median_age")
p5 <- edaPlot(data$female_median_age,"female_median_age")
p6 <- edaPlot(data$no_establishments,"no_establishments")
p7 <- edaPlot(data$paid_employees,"paid_employees")
p8 <- edaPlot(data$payroll_quarter1,"payroll_quarter1")
p9 <- edaPlot(data$annual_payroll,"annual_payroll")
p10 <- edaPlot(data$revenue,"revenue")

Rmisc::multiplot(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, cols = 2)

#' 
#' ***
#' 
#' **Univariate Analysis-II**
#' 
#' Most of the zipcodes have males:
#' 
#' 1. Between 15-44 years of age
#' 2. Over 60 years of age
#' 3. Between 5-14 years of age
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
p1 <- edaPlot(data$perc_male_under_5yrs,"perc_male_under_5yrs")
p2 <- edaPlot(data$perc_male_5_14yrs,"perc_male_5_14yrs")
p3 <- edaPlot(data$perc_male_15_44yrs,"perc_male_15_44yrs")
p4 <- edaPlot(data$perc_male_45_49yrs,"perc_male_45_49yrs")
p5 <- edaPlot(data$perc_male_50_54yrs,"perc_male_50_54yrs")
p6 <- edaPlot(data$perc_male_55_59yrs,"perc_male_55_59yrs")
p7 <- edaPlot(data$perc_male_over_60yrs,"perc_male_over_60yrs")

Rmisc::multiplot(p1, p2, p3, p4, p5, p6, p7, cols = 2)

#' 
#' ***
#' 
#' **Univariate Analysis-III**
#' 
#' Most of the zipcodes have females:
#' 
#' 1. Between 15-44 years of age
#' 2. Over 60 years of age
#' 3. Between 5-14 years of age
## ----warning=FALSE, message=FALSE----------------------------------------
p1 <- edaPlot(data$perc_female_under_5yrs,"perc_female_under_5yrs")
p2 <- edaPlot(data$perc_female_5_14yrs,"perc_female_5_14yrs")
p3 <- edaPlot(data$perc_female_15_44yrs,"perc_female_15_44yrs")
p4 <- edaPlot(data$perc_female_45_49yrs,"perc_female_45_49yrs")
p5 <- edaPlot(data$perc_female_50_54yrs,"perc_female_50_54yrs")
p6 <- edaPlot(data$perc_female_55_59yrs,"perc_female_55_59yrs")
p7 <- edaPlot(data$perc_female_over_60yrs,"perc_female_over_60yrs")

Rmisc::multiplot(p1, p2, p3, p4, p5, p6, p7, cols = 2)

#' 
#' ***
#' 
#' **Univariate Analysis-IV**
#' 
#' Popular Products are equally distributed among college, life and retirement.
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
ggplot(data, aes(x=popular_product)) +
  geom_bar()

#' 
#' ***
#' 
#' **Revenue Bivariate Analysis-I**
#' 
#' *Note: See the last row only*
#' 
#' Revenue has high positive correlation with:
#' 
#' * annual_payroll
#' * payroll_quarter1
#' * paid_employees
#' * no_establishments
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
df1 <- select(data, tot_population:tot_female_population
              , male_median_age:annual_payroll, revenue)

pairs(df1)

#' 
#' *Note: See the last column only*
#' 
#' The above inference is verified by the correlation plot
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
ggcorr(df1, label = TRUE, angle = 20)

#' 
#' ***
#' 
#' **Revenue Bivariate Analysis-II**
#' 
#' *Note: See the last row only*
#' 
#' There does not seem any significant correlations.
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
df2 <- select(data, perc_male_under_5yrs:perc_male_over_60yrs, revenue)

pairs(df2)

#' 
#' *Note: See the last column only*
#' 
#' Observations:
#' 
#' * Revenue is negatively correlated with perc_male_over_60yrs. This does make sense as older the population lower the revenue generated.
#' * Revenue is positively correlated with perc_male_15_44yrs. This does make sense as younger the population higher the revenue generated.
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
ggcorr(df2, label = TRUE, angle = 20)

#' 
#' ***
#' 
#' **Revenue Bivariate Analysis-III**
#' 
#' *Note: See the last row only*
#' 
#' There does not seem any significant correlations.
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
df3 <- select(data, perc_female_under_5yrs:perc_female_over_60yrs, revenue)

pairs(df3)

#' 
#' Observations:
#' 
#' * Revenue is negatively correlated with perc_female_over_60yrs. This does make sense as older the population lower the revenue generated.
#' * Revenue is positively correlated with perc_female_15_44yrs. This does make sense as younger the population higher the revenue generated.
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
ggcorr(df3, label = TRUE, angle = 20)

#' 
#' ***
#' 
#' **Popularity Bivariate Analysis-I**
#' 
#' Variables which have separation in distribution of Popular Products:
#' 
#' * tot_population 
#' * tot_male_population
#' * tot_female_population 
#' * male_median_age
#' * female_median_age
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
distribution_plot <- function(x, name)
{
  ggplot(data, aes(x=x, fill=popular_product)) +
    geom_histogram(position = 'dodge', aes(y=..density..)) +
    labs(x=name)
}

p1 <- distribution_plot(data$tot_population,"tot_population")
p2 <- distribution_plot(data$tot_male_population,"tot_male_population")
p3 <- distribution_plot(data$tot_female_population,"tot_female_population")
p4 <- distribution_plot(data$male_median_age,"male_median_age")
p5 <- distribution_plot(data$female_median_age,"female_median_age")
p6 <- distribution_plot(data$no_establishments,"no_establishments")
p7 <- distribution_plot(data$paid_employees,"paid_employees")
p8 <- distribution_plot(data$payroll_quarter1,"payroll_quarter1")
p9 <- distribution_plot(data$annual_payroll,"annual_payroll")
p10 <- distribution_plot(data$revenue,"revenue")

Rmisc::multiplot(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, cols = 2)

#' 
#' ***
#' 
#' **Popularity Bivariate Analysis-II**
#' 
#' Variables which have separation in distribution of Popular Products:
#' 
#' * perc_male_under_5yrs 
#' * perc_male_15_44yrs
#' * perc_male_45_49yrs 
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
p1 <- distribution_plot(data$perc_male_under_5yrs,"perc_male_under_5yrs")
p2 <- distribution_plot(data$perc_male_5_14yrs,"perc_male_5_14yrs")
p3 <- distribution_plot(data$perc_male_15_44yrs,"perc_male_15_44yrs")
p4 <- distribution_plot(data$perc_male_45_49yrs,"perc_male_45_49yrs")
p5 <- distribution_plot(data$perc_male_50_54yrs,"perc_male_50_54yrs")
p6 <- distribution_plot(data$perc_male_55_59yrs,"perc_male_55_59yrs")
p7 <- distribution_plot(data$perc_male_over_60yrs,"perc_male_over_60yrs")

Rmisc::multiplot(p1, p2, p3, p4, p5, p6, p7, cols = 2)

#' 
#' ***
#' 
#' **Popularity Bivariate Analysis-III**
#' 
#' Variables which have separation in distribution of Popular Products:
#' 
#' * perc_female_15_44yrs
#' * perc_female_45_49yrs 
#' 
#' 
## ----warning=FALSE, message=FALSE----------------------------------------
p1 <- distribution_plot(data$perc_female_under_5yrs,"perc_female_under_5yrs")
p2 <- distribution_plot(data$perc_female_5_14yrs,"perc_female_5_14yrs")
p3 <- distribution_plot(data$perc_female_15_44yrs,"perc_female_15_44yrs")
p4 <- distribution_plot(data$perc_female_45_49yrs,"perc_female_45_49yrs")
p5 <- distribution_plot(data$perc_female_50_54yrs,"perc_female_50_54yrs")
p6 <- distribution_plot(data$perc_female_55_59yrs,"perc_female_55_59yrs")
p7 <- distribution_plot(data$perc_female_over_60yrs,"perc_female_over_60yrs")

Rmisc::multiplot(p1, p2, p3, p4, p5, p6, p7, cols = 2)

#' 
#' ## Model {.tabset .tabset-fade .tabset-pills}
#' 
#' ### Model Building
#' 
#' **Dividing data into train and test set**
#' 
## ------------------------------------------------------------------------
# 80-20 train vs test split
set.seed(1)
index<-sample(nrow(data),nrow(data)*0.8)
train<-data[index,]
test<-data[-index,]

#' 
#' ***
#' 
#' **Building the model to predict Revenue**
#' 
#' * The following model has been built using Linear Regression
#' * The variable selection has been done using forward selection (BIC)
#' 
## ---- results = 'hide'---------------------------------------------------
# Null Model - Regress square feet on only the intercept
nullmodel=lm(revenue~1, data=train)

# Full Model - Regress square feet on all predictor variables
fullmodel=lm(revenue ~  .-Id2-geographic_area_name-popular_product
             , data=train)

# Final Model built using stepwise variable selection (BIC)
model_revenue <- step(nullmodel, scope=list(lower=nullmodel, upper=fullmodel),
                         direction = c("forward"), k=log(nrow(train)))

#' 
#' ***
#'   
#' **Model Summary**
#' 
#' The adjusted R square of the model is ~99%
#' 
## ------------------------------------------------------------------------
summary(model_revenue)

#' 
#' ***
#' 
#' **Calculating Mean Square Error on Train and Test Set**
#' 
#' Train and Test MSEs are comparable, thus there seems to be no overfitting
#' 
## ------------------------------------------------------------------------
# prediction on train set
linear_regression_pred_train <- predict(model_revenue)

# prediction on test set
linear_regression_pred_test <- predict(model_revenue,
                                      newdata=test)

# train MSE
linear_regression_train_mse <- mean((linear_regression_pred_train-train$revenue)^2)

# test MSE
linear_regression_test_mse <- mean((linear_regression_pred_test-test$revenue)^2)

cat("Train MSE:", linear_regression_train_mse, "| Test MSE:", linear_regression_test_mse)

#' 
#' ***
#' 
#' **Building the model to predict the popularity of product**
#' 
#' * The following model has been built using Multinomial Logistic Regression
#' * The variable selection has been done using forward selection (AIC)
#' 
## ----results = 'hide'----------------------------------------------------
# Multinomial Logistics Regression
model_pop_product <- multinom(popular_product ~ 
                              male_median_age
                              +female_median_age
                              +tot_population
                              +tot_male_population
                              +tot_female_population
                              +perc_male_under_5yrs
                              +perc_male_15_44yrs
                              +perc_male_45_49yrs
                              +perc_male_over_60yrs
                              +perc_female_under_5yrs
                              +perc_female_15_44yrs
                              +perc_female_45_49yrs
                              +perc_female_over_60yrs
                              , select(train, -geographic_area_name, -Id2, -revenue), maxit=200)

# performing forward selection (AIC)
model_pop_product_step <- step(model_pop_product)

#' 
#' ***
#' 
#' **Model Summary**
#' 
## ------------------------------------------------------------------------
summary(model_pop_product_step)

#' 
#' ***
#' 
#' **Confusion matrix on train set**
#' 
#' Accuracy Rate: 98.84%
## ------------------------------------------------------------------------
conf_matrix_train <-
  table(train$popular_product,predict(model_pop_product))

conf_matrix_train

#' 
#' ***
#' 
#' **Confusion matrix on test set**
#' 
#' Accuracy Rate: 97.83%
## ------------------------------------------------------------------------
conf_matrix_test <-
  table(test$popular_product,predict(model_pop_product, newdata = test))

conf_matrix_test

#' 
#' ### Model Diagonostics
#' 
#' 1. **Errors are normally distributed with mean=0**
#'   
#' Using a Q-Q Plot, errors seem to be normally distributed. However, both the tails seem to be heavily skewed due to outliers.
#' 
## ------------------------------------------------------------------------
# Constructing a dataframe containing model attributes
model_attributes1 <-
  data.frame(index=1:nrow(train),
             residuals = model_revenue$residuals, 
             fitted_values = model_revenue$fitted.values)

# Constructing Q-Q Plot
qqnorm(model_attributes1$residuals)
qqline(model_attributes1$residuals, col='red')

#' 
#' ***
#'   
#' 2. **Uncorrelated Errors **
#'   
#' There seems to be **no pattern** for the errors over time (index). Thus we can safely assume that the errors are uncorrelated.
#' 
## ------------------------------------------------------------------------
# Plotting Residuals over Time
model_attributes1 %>%
  ggplot(aes(x=index,y=residuals)) +
  geom_point()

#' 
#' ***
#'   
#' 3. **Constance Variance**
#'   
#' We can clearly see that the residuals are **constantly varied** across the majority of the fitted values. However, for very large fitted values, the variation seems to fan out. If we remove the outliers, we would remove the fan shaped variance as well.
#' 
## ------------------------------------------------------------------------
# Residuals vs Fitted-Value Plot
ggplot(model_attributes1, aes(x=fitted_values,y=residuals)) +
  geom_point() +
  geom_hline(yintercept = 0, color = "red") +
  geom_hline(yintercept = 3, color = "blue") +
  geom_hline(yintercept = -3, color = "blue")

#' 
#' ***
#'   
#' 4. **Predictor Variables are independent of each other**
#'   
#' **Variation Inflation Factor** is high for a few variables like *annual_payroll*, *payroll_quarter1* and *paid_employees*. We will need to remove some of these to reduce multi-collinearity 
#' 
## ------------------------------------------------------------------------
vif(model_revenue)

#' 
#' ***
#'   
#' 5. **No influential outliers**
#'   
#' Almost all **standardized errors** are below the absolute value of 5. However, there are a few observation that are over the absolute value of 5 and hence can be considered as influential outliers. In an ideal case, these should be removed.
#' 
## ------------------------------------------------------------------------
# Plotting Studentized/Standardized Errors
rstan <- rstandard(model_revenue)  
plot(rstan)

#' 
#' 
#' ### Corrected Model
#' 
#' **Removing Influential Outliers**
#' 
## ------------------------------------------------------------------------
# calculating cooks distance
cooksd <- cooks.distance(model_revenue)

# influential outliers row numbers
influential <- as.numeric(names(cooksd)[(cooksd > mean(cooksd, na.rm=T))]) 

# remove influential outliers
train <- train[-influential,]

#' 
#' ***
#' 
#' **Building the model to predict Revenue**
#' 
#' * The following model has been built using Linear Regression
#' * The variable selection has been done using forward selection (BIC)
#' * *annual_payroll* and *paid_employees* is removed to reduce multi-collinearity
#' 
## ---- results = 'hide'---------------------------------------------------
# Null Model - Regress square feet on only the intercept
nullmodel=lm(revenue~1, data=train)

# Full Model - Regress square feet on all predictor variables except annual_payroll
fullmodel=lm(revenue ~  .-Id2-geographic_area_name-popular_product-annual_payroll-paid_employees
             , data=train)

# Final Model built using stepwise variable selection (BIC)
model_revenue <- step(nullmodel, scope=list(lower=nullmodel, upper=fullmodel),
                         direction = c("forward"), k=log(nrow(train)))

#' 
#' ***
#'   
#' **Model Summary**
#' 
#' The adjusted R square of the model is ~99%
#' 
## ------------------------------------------------------------------------
summary(model_revenue)

#' 
#' ***
#' 
#' **Calculating Mean Square Error on Train and Test Set**
#' 
#' Train and Test MSEs are comparable, thus there seems to be no overfitting
#' 
## ------------------------------------------------------------------------
# prediction on train set
linear_regression_pred_train <- predict(model_revenue)

# prediction on test set
linear_regression_pred_test <- predict(model_revenue,
                                      newdata=test)

# train MSE
linear_regression_train_mse <- mean((linear_regression_pred_train-train$revenue)^2)

# test MSE
linear_regression_test_mse <- mean((linear_regression_pred_test-test$revenue)^2)

cat("Train MSE:", linear_regression_train_mse, "| Test MSE:", linear_regression_test_mse)

#' 
#' ***
#' 
#' **Building the model to predict the popularity of product**
#' 
#' * The following model has been built using Multinomial Logistic Regression
#' * The variable selection has been done using forward selection (AIC)
#' 
## ----results = 'hide'----------------------------------------------------
# Multinomial Logistics Regression
model_pop_product <- multinom(popular_product ~ 
                              male_median_age
                              +female_median_age
                              +tot_population
                              +tot_male_population
                              +tot_female_population
                              +perc_male_under_5yrs
                              +perc_male_15_44yrs
                              +perc_male_45_49yrs
                              +perc_male_over_60yrs
                              +perc_female_under_5yrs
                              +perc_female_15_44yrs
                              +perc_female_45_49yrs
                              +perc_female_over_60yrs
                              , select(train, -geographic_area_name, -Id2, -revenue), maxit=200)

# performing forward selection (AIC)
model_pop_product_step <- step(model_pop_product)

#' 
#' ***
#' 
#' **Model Summary**
#' 
## ------------------------------------------------------------------------
summary(model_pop_product_step)

#' 
#' ***
#' 
#' **Confusion matrix on train set**
#' 
#' Accuracy Rate: 97.76%
## ------------------------------------------------------------------------
conf_matrix_train <-
  table(train$popular_product,predict(model_pop_product))

conf_matrix_train

#' 
#' ***
#' 
#' **Confusion matrix on test set**
#' 
#' Accuracy Rate: 97.83%
## ------------------------------------------------------------------------
conf_matrix_test <-
  table(test$popular_product,predict(model_pop_product, newdata = test))

conf_matrix_test

#' 
#' ### Corrected Model Diagonostics
#' 
#' 1. **Errors are normally distributed with mean=0**
#'   
#' Using a Q-Q Plot, errors seem to be normally distributed.
#' 
## ------------------------------------------------------------------------
# Constructing a dataframe containing model attributes
model_attributes1 <-
  data.frame(index=1:nrow(train),
             residuals = model_revenue$residuals, 
             fitted_values = model_revenue$fitted.values)

# Constructing Q-Q Plot
qqnorm(model_attributes1$residuals)
qqline(model_attributes1$residuals, col='red')

#' 
#' ***
#'   
#' 2. **Uncorrelated Errors **
#'   
#' There seems to be **no pattern** for the errors over time (index). Thus we can safely assume that the errors are uncorrelated.
#' 
## ------------------------------------------------------------------------
# Plotting Residuals over Time
model_attributes1 %>%
  ggplot(aes(x=index,y=residuals)) +
  geom_point()

#' 
#' ***
#'   
#' 3. **Constance Variance**
#'   
#' We can clearly see that the residuals are **constantly varied** across the fitted values.
#' 
## ------------------------------------------------------------------------
# Residuals vs Fitted-Value Plot
ggplot(model_attributes1, aes(x=fitted_values,y=residuals)) +
  geom_point() +
  geom_hline(yintercept = 0, color = "red") +
  geom_hline(yintercept = 3, color = "blue") +
  geom_hline(yintercept = -3, color = "blue")

#' 
#' ***
#'   
#' 4. **Predictor Variables are independent of each other**
#'   
#' **Variation Inflation Factor** <10 for all variables. Thus their is no multi-collinearity.
#' 
## ------------------------------------------------------------------------
vif(model_revenue)

#' 
#' ***
#'   
#' 5. **No influential outliers**
#'   
#' Almost all **standardized errors** are below the absolute value of 5.
#' 
## ------------------------------------------------------------------------
# Plotting Studentized/Standardized Errors
rstan <- rstandard(model_revenue)  
plot(rstan)

#' 
#' ### Model Interpretation
#' 
#' **Linear Regression - Predicting Revenue**
#' 
#' * Revenue = output variable
#' 
#' * **99% variance** in the output variable is explained by:
#'     * no_establishments
#'     * payroll_quarter1
#'     * perc_male_5_14yrs
#'     * tot_population
#'     * perc_male_15_44yrs
#'     * perc_female_over_60yrs
#'     * perc_female_15_44yrs
#'     
#' * All held constant, with 1 unit increase in no_establishments, the average revenue **increases by $113.86**.
#' 
#' * A more concrete way of elaborating the above point would be: All held constant, we are **95 % confident** that with 1 unit increase in no_establishments, the average revenue **increases by $112.78 - $114.94**.
#' 
#' * All other predictor variables can be interpretted in the same way.
#' 
#' * The **t-tests** correspond to the following hypothesis test:
#'     + H0: Beta = 0
#'     + HA: Beta !=0
#'     + For all p-values < 0.05, we reject H0
#'     + All predictor variables have p-value < 0.05
#'     
#' * The **f-test** correspond to the following hypothesis test:
#'     + H0: All Beta's = 0
#'     + HA: At least one Beta != 0
#'     + As p-value < 0.05, we reject H0. **Thus our model as a whole is significant**. 
#'     
#' ***
#' 
#' **Multinomial Logistic Regression**
#' 
#' * Final variables selected are as follows:
#'     + male_median_age
#'     + tot_population
#'     + tot_male_population
#'     + tot_female_population
#'     + perc_male_under_5yrs
#'     + perc_male_15_44yrs
#'     + perc_male_45_49yrs
#'     + perc_female_15_44yrs
#'     + perc_female_45_49yrs
#'     + perc_female_over_60yrs
#'     
#' * The interpretation of the model is as follows:
#'     + With 1 unit increase in perc_male_15_44yrs:
#'         + odds of pop product = *life* relative to pop product = *college* increases by a factor of 25.71
#'         + odds of pop product = *life* relative to pop product = *college* increases by a factor of 1.05
#'     + All other variables can be interpretted in the same way
#' 
#' * AIC - which a measure of the quality of the model - is 636.72
#' 
#' * Accuracy Rate on test set i.e. percentage of popular products correctly classified are 97.83%
#' 
#' ## Insights
#' 
#' ### Predicting Revenue Generated
#' 
#' * Revenue generated in each zipcode is predicted using a **linear regression model**.
#' 
#' * We are getting an **almost perfect model (99% Adjusted R-Square)** for predicting the revenue generated in each zipcode. Thus, we can very accurately predict the same and take actions to increase/decrease the revenue in selected zip codes.
#' 
#' * Revenue highly depends upon these factors:
#'     + no_establishments
#'     + payroll_quarter1
#'     + perc_male_5_14yrs
#'     + tot_population
#'     + perc_male_15_44yrs
#'     + perc_female_over_60yrs
#'     + perc_female_15_44yrs
#'     
#' * MSE(Train): 36752185 | MSE(Test): 321499258
#'     
#' ### Predicting Popular Product
#' 
#' * Popular product in each zipcode is predicted using a **multinomial logistic regression model**.
#' 
#' * We are getting **high accuracy rate** on both train and test set for predicting the popular products:
#'     * Accuracy Rate(Train): 97.86%
#'     * Accuracy Rate(Test): 97.83%
#' 
#' * Popular products highly depends upon these factors:
#'     + male_median_age
#'     + tot_population
#'     + tot_male_population
#'     + tot_female_population
#'     + perc_male_under_5yrs
#'     + perc_male_15_44yrs
#'     + perc_male_45_49yrs
#'     + perc_female_15_44yrs
#'     + perc_female_45_49yrs
#'     + perc_female_over_60yrs
#'     
#' * Model AIC: 636.7282
#' 
#' ### Future Work
#' 
#' 1. Perform cross-validation to find the optimal **k** in k-nearest neighbour algorithm.
#' 2. Perform cross-validation on both the **regression and classfication models** to verify that the models are not overfitting.
#' 3. Perform **transformation on response and/or predictor variables** to satisfy the assumptions of the linear regression model  (better than current model).
#' 4. Use **different variable selection techniques** like backward, stepwise and lasso on parameters like adjusted R square, AIC, BIC, deviance, p-value etc.
#' 5. Use more **advanced models** like decision trees, random forest, bagging and boosting to increase accuracy.
#' 
