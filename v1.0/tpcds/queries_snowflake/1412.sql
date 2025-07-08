
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT wr_order_number) AS return_count,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_quantity) DESC) AS return_rank
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CustomerPurchases AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS purchase_count,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TotalReturns AS (
    SELECT 
        r.wr_returning_customer_sk,
        r.total_return_quantity,
        r.return_count,
        cp.purchase_count,
        cp.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        RankedReturns AS r
    JOIN 
        CustomerPurchases AS cp ON r.wr_returning_customer_sk = cp.ws_bill_customer_sk
    LEFT JOIN 
        CustomerDemographics AS cd ON r.wr_returning_customer_sk = cd.c_customer_sk
    WHERE 
        r.return_count > 1
)
SELECT 
    *,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        ELSE CAST(total_sales AS CHAR)
    END AS sales_info,
    CASE 
        WHEN cd_gender = 'F' AND cd_marital_status = 'M' THEN 'Female-Married'
        WHEN cd_gender = 'F' THEN 'Female-Single'
        WHEN cd_gender = 'M' AND cd_marital_status = 'M' THEN 'Male-Married'
        ELSE 'Male-Single'
    END AS demographic_label
FROM 
    TotalReturns
WHERE 
    total_return_quantity > (SELECT AVG(total_return_quantity) FROM RankedReturns) 
    AND (cd_gender IS NOT NULL OR cd_marital_status IS NOT NULL)
ORDER BY 
    total_return_quantity DESC
FETCH FIRST 100 ROWS ONLY;
