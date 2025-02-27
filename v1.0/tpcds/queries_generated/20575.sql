
WITH RankedSales AS (
    SELECT 
        ws.web_site_id, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        COALESCE(NULLIF(SUM(ws.ws_quantity) OVER (PARTITION BY ws.web_site_id), 0), 1) AS total_quantity, 
        CASE 
            WHEN SUM(ws.ws_sales_price) > 500 THEN 'High'
            WHEN SUM(ws.ws_sales_price) BETWEEN 200 AND 500 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category 
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    WHERE c.c_last_name LIKE 'A%' AND c.c_preferred_cust_flag = 'Y'
),
CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk, 
        SUM(CASE WHEN sr_return_quantity IS NULL THEN 0 ELSE sr_return_quantity END) AS total_returns
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT 
        r.sales_rank, 
        r.web_site_id, 
        r.ws_order_number,
        r.ws_sales_price,
        r.ws_quantity,
        COALESCE(cr.total_returns, 0) AS total_returns,
        CASE 
            WHEN r.total_quantity > 10 THEN 'Bulk'
            ELSE 'Individual'
        END AS purchase_type,
        ROW_NUMBER() OVER (PARTITION BY r.web_site_id ORDER BY r.sales_rank) AS row_num
    FROM RankedSales r
    LEFT JOIN CustomerReturns cr ON r.ws_order_number = cr.sr_returning_customer_sk
)
SELECT 
    web_site_id, 
    SUM(ws_sales_price * ws_quantity) AS total_sales_value,
    AVG(ws_sales_price) AS average_price,
    COUNT(*) AS total_orders,
    MAX(total_returns) AS max_returns,
    MIN(total_returns) AS min_returns,
    STRING_AGG(DISTINCT purchase_type) AS purchase_types
FROM SalesWithReturns
WHERE row_num <= 10
GROUP BY web_site_id
ORDER BY total_sales_value DESC
LIMIT 5
UNION ALL
SELECT 
    'TOTALS' AS web_site_id,
    SUM(ws_sales_price * ws_quantity),
    AVG(ws_sales_price),
    COUNT(*),
    SUM(COALESCE(total_returns, 0)),
    NULL,
    NULL
FROM SalesWithReturns;
