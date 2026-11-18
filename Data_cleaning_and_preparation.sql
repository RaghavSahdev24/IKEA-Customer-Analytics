-- 1. DATABASE CREATION
Create DataBase EcomerceCustomerAnalytics;


-- 2. SOURCE DATA ROW COUNT VALIDATION
SELECT COUNT(*) AS Rows_2009_2010 FROM dbo.[Year 2009-2010];
SELECT COUNT(*) AS Rows_2010_2011 FROM dbo.[Year 2010-2011];


-- 3. COMBINE BOTH YEARS AND CONVERT DATA TYPES SAFELY
    Invoice, StockCode, Description, Quantity,
    COALESCE(
        TRY_CONVERT(datetime2, InvoiceDate, 120),
        TRY_CONVERT(datetime2, InvoiceDate, 105)
    ) As InvoiceDate,

    TRY_CONVERT(decimal(10,2), Price) As Price,
    Customer_ID, Country, '2009-2010' As SourceSheet
into dbo.RetailCombined
FROM dbo.[Year 2009-2010]

UNION ALL

Select
    Invoice, StockCode, Description, Quantity,
    COALESCE(
        TRY_CONVERT(datetime2, InvoiceDate, 120),
        TRY_CONVERT(datetime2, InvoiceDate, 105)
    ) As InvoiceDate,
    TRY_CONVERT(decimal(10,2), Price) As Price,
    Customer_ID, Country, '2010-2011' As SourceSheet
FROM dbo.[Year 2010-2011];

-- 4. DATA TYPE CONVERSION VALIDATION (CONFIRM THE CONVERSION WORKED CLEANLY)
SELECT COUNT(*) AS Total_Rows FROM dbo.RetailCombined;
SELECT COUNT(*) AS Failed_Dates FROM dbo.RetailCombined WHERE InvoiceDate IS NULL;
SELECT COUNT(*) AS Failed_Prices FROM dbo.RetailCombined WHERE Price IS NULL;


-- 5. DATA QUALITY CHECKS AND DUPLICATE RECORD IDENTIFICATION
-- Check 1 - MISSING CUSTOMER ID
SELECT COUNT(*) AS Missing_CustomerID
FROM dbo.RetailCombined Where Customer_ID is NULL;

-- Check 2 - NEGATIVE OR ZERO QUANTITY
SELECT COUNT(*) AS Negative_Qty
FROM dbo.RetailCombined Where Quantity <= 0;

-- Check 3 - MISSING DESCRIPTION
SELECT COUNT(*) AS Missing_DISCRIPTION
FROM dbo.RetailCombined Where Description is NULL;

-- Check 4 - EXACT DUPLICATE ROWS
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country,
	   COUNT(*) AS ExactDupeCount
FROM dbo.RetailCombined
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country
Having COUNT(*) > 1;


-- 6. DEDUPLICATE AND PRODUCT THE FINAL CLEANED TABLE
WITH Deduped AS (
	SELECT *,
	   ROW_NUMBER() OVER (
		   PARTITION BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country
		   ORDER BY (SELECT NULL)
       ) AS RowNum
   FROM dbo.RetailCombined
)
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country, SourceSheet
INTO dbo.RetailCleaned
FROM Deduped
WHERE RowNum = 1;


-- 8. FINAL CLEANED DATA VALIDATION
SELECT * FROM dbo.RetailCleaned;


