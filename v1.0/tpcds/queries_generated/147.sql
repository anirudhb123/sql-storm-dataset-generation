
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(DISTINCT sr_ticket_number) AS total_returns, 
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
CustomerPurchases AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_purchases,
        SUM(ws_net_profit) AS total_purchase_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
CustomerStatistics AS (
    SELECT 
        COALESCE(cp.ws_bill_customer_sk, cr.sr_customer_sk) AS customer_sk,
        COALESCE(cp.total_purchases, 0) AS purchases,
        COALESCE(cp.total_purchase_value, 0) AS purchase_value,
        COALESCE(cr.total_returns, 0) AS returns,
        COALESCE(cr.total_return_value, 0) AS return_value
    FROM 
        CustomerPurchases cp
    FULL OUTER JOIN 
        CustomerReturns cr ON cp.ws_bill_customer_sk = cr.sr_customer_sk
)
SELECT 
    d.d_year,
    SUM(cs.total_purchase_value) AS total_sales_value,
    AVG(cs.purchase_value - cs.return_value) AS avg_net_sales_per_customer,
    COUNT(cs.customer_sk) AS customer_count,
    COUNT(CASE WHEN cs.returns > 0 THEN 1 END) AS customers_with_returns
FROM 
    CustomerStatistics cs
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) 
                                    FROM web_sales 
                                    WHERE ws_bill_customer_sk = cs.customer_sk
                                    AND ws_sold_date_sk < CURRENT_DATE)
WHERE 
    d.d_year BETWEEN 2021 AND 2023
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year ASC;
