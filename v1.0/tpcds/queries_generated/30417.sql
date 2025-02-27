
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(wr_order_number) AS total_orders
    FROM web_returns
    GROUP BY wr_returning_customer_sk
    UNION ALL
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_returned_amt,
        COUNT(cr_order_number) AS total_orders
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
DateSales AS (
    SELECT 
        d.d_date AS sales_date,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cr.total_returned) AS total_returns,
        SUM(cr.total_returned_amt) AS total_returned_amt
    FROM customer_demographics cd
    LEFT JOIN CustomerReturns cr ON cd.cd_demo_sk = cr.wr_returning_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
SalesComparison AS (
    SELECT 
        CASE 
            WHEN total_sales > 10000 THEN 'High'
            WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low' 
        END AS sales_category,
        COUNT(DISTINCT cd.cd_demo_sk) AS customer_count
    FROM DateSales ds
    INNER JOIN CustomerDemographics cd ON ds.sales_date >= DATEADD(month, -3, GETDATE())
    GROUP BY CASE 
        WHEN total_sales > 10000 THEN 'High'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low' 
    END
)
SELECT 
    dc.cd_gender,
    dc.cd_marital_status,
    sc.sales_category,
    COUNT(dc.cd_demo_sk) AS gender_marital_count,
    SUM(dc.total_returns) AS total_returns,
    SUM(dc.total_returned_amt) AS total_returned_amount
FROM CustomerDemographics dc
LEFT JOIN SalesComparison sc ON 1=1
GROUP BY dc.cd_gender, dc.cd_marital_status, sc.sales_category
ORDER BY total_returned_amount DESC, gender_marital_count DESC;
