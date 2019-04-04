The sample data given is a portion of the American Community Survey 2015 from census.gov. It contains several fields detailing population, gender, and business metrics grouped by selected ZIP codes throughout the United States. 

'census_train.csv' is the training data file, containing several independent variables without response columns. The key here is an ID which can be joined on in the geo_info dataset.

'revenues_products.csv' contains the responses for the training data. This can be joined to the training set on the ZIP code. The summed revenues here total around 500m.

'geo_info.csv' is a joining/lookup dataset. It contains the IDs and their respective ZIP codes.

'census_test.csv' is the held out dataset, around 77% of the total data. This set does not contain responses.

There is also a short readme provided by census.gov called 'BP_2015_00CZ1.txt' which contains a data dictionary necessary to convert certain string values in the data files into numeric values.

The column names should mostly be self explanatory. The two dependent variables represent:

'Revenue': Revenue earned by the company for the given ZIP code
'Pop_product': The most popular product sold by a financial institution in the given ZIP code. Options include college fund, retirement fund, and life insurance.