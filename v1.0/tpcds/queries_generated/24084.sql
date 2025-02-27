
WITH CustomerReturns AS (
    SELECT 
        COALESCE(sr_customer_sk, wr_returning_customer_sk) AS Customer_SK,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS Total_Returns,
        COUNT(DISTINCT COALESCE(sr_ticket_number, wr_order_number)) AS Return_Transactions
    FROM 
        store_returns sr
    FULL OUTER JOIN 
        web_returns wr ON sr_returning_customer_sk = wr_returning_customer_sk
    GROUP BY 
        COALESCE(sr_customer_sk, wr_returning_customer_sk)
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.gender = 'M' THEN 'Male'
            WHEN cd.gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS Gender,
        cd.cd_marital_status AS Marital_Status,
        DENSE_RANK() OVER(PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS Purchase_Rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnAnalysis AS (
    SELECT 
        cd.Gender,
        cd.Marital_Status,
        cr.Total_Returns,
        cr.Return_Transactions,
        COALESCE(cr.Total_Returns / NULLIF(cr.Return_Transactions, 0), 0) AS Returns_Per_Transaction
    FROM 
        CustomerReturns cr
    JOIN 
        CustomerDemographics cd ON cr.Customer_SK = cd.c_customer_sk
)
SELECT 
    ra.Gender,
    ra.Marital_Status,
    AVG(ra.Returns_Per_Transaction) AS Avg_Returns_Per_Transaction,
    COUNT(*) AS Customer_Count,
    STDDEV(ra.Returns_Per_Transaction) AS StdDev_Returns_Per_Transaction
FROM 
    ReturnAnalysis ra
WHERE 
    ra.Returns_Per_Transaction > (SELECT AVG(Returns_Per_Transaction) FROM ReturnAnalysis)
GROUP BY 
    ra.Gender, ra.Marital_Status
HAVING 
    COUNT(*) > 1
ORDER BY 
    Gender, Marital_Status;
