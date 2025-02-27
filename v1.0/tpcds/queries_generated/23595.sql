
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returns,
        SUM(cr.return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT cr.returning_cdemo_sk) AS unique_customers
    FROM 
        catalog_returns cr
    WHERE 
        cr.returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_moy IN (6, 7))
    GROUP BY 
        cr.returning_customer_sk
),
SalesWithNulls AS (
    SELECT 
        coalesce(rs.web_site_sk, 'UNKNOWN') as web_site,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.ws_sales_price,
        CASE 
            WHEN rs.ws_quantity IS NULL THEN 'Quantity Missing' 
            ELSE 'Quantity Available' 
        END AS quantity_status
    FROM 
        RankedSales rs
    FULL OUTER JOIN CustomerReturns cr ON rs.ws_order_number = cr.returning_customer_sk
)
SELECT 
    sw.web_site,
    COUNT(sw.ws_order_number) AS total_orders,
    SUM(sw.total_returns) AS cumulative_returns,
    AVG(sw.total_return_amount) AS avg_return_amount,
    COUNT(DISTINCT CASE WHEN sw.quantity_status = 'Quantity Missing' THEN sw.ws_order_number END) AS missing_quantity_orders,
    SUM(CASE WHEN sw.ws_sales_price IS NULL THEN 1 ELSE 0 END) AS null_sales_count
FROM 
    SalesWithNulls sw
WHERE 
    sw.ws_sales_price >= 50 OR sw.total_returns > 0
GROUP BY 
    sw.web_site
HAVING 
    COUNT(sw.ws_order_number) > 10
ORDER BY 
    cumulative_returns DESC
LIMIT 10;
