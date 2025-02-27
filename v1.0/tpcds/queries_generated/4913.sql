
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amt) AS total_return_amt,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
SalesAnalysis AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
JoinResults AS (
    SELECT 
        coalesce(c.c_customer_sk, cr.cr_returning_customer_sk) AS customer_sk,
        COALESCE(s.total_sales_quantity, 0) AS total_sales,
        COALESCE(c.total_returned, 0) AS total_returns,
        COALESCE(s.avg_net_paid, 0) AS avg_net_paid,
        COALESCE(c.total_return_amt, 0) AS total_return_amt
    FROM 
        CustomerReturns c
    FULL OUTER JOIN 
        SalesAnalysis s ON c.cr_returning_customer_sk = s.customer_sk
)
SELECT 
    customer_sk,
    total_sales,
    total_returns,
    avg_net_paid,
    total_return_amt,
    (CASE 
        WHEN total_sales = 0 THEN 0 
        ELSE (total_returns::decimal / total_sales) 
    END) AS return_ratio,
    (SELECT COUNT(*) FROM customer WHERE c_customer_sk = j.customer_sk) AS customer_exists
FROM 
    JoinResults j
WHERE 
    (total_sales > 100 OR total_returns > 50) 
    AND avg_net_paid IS NOT NULL
ORDER BY 
    return_ratio DESC
LIMIT 100;
