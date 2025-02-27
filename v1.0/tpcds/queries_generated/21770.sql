
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank_paid,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 10001 AND 10010
),
CustomerReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr_returning_customer_sk) AS return_customers
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
SalesWithReturns AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.rank_paid,
        r.total_quantity,
        r.unique_customers,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.return_customers, 0) AS return_customers
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns c ON r.ws_item_sk = c.cr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_quantity,
    s.unique_customers,
    s.total_returns,
    CASE 
        WHEN s.total_returns > 0 THEN 
            ROUND((CAST(s.total_returns AS DECIMAL) / NULLIF(s.total_quantity, 0)) * 100, 2)
        ELSE 0 
    END AS return_rate_percentage,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk) 
     FROM web_sales 
     WHERE ws_item_sk = s.ws_item_sk 
     AND ws_net_paid > 50) AS high_value_customers
FROM 
    SalesWithReturns s
WHERE 
    s.rank_paid = 1 
    AND (s.return_rate_percentage IS NULL OR s.return_rate_percentage > 5)
ORDER BY 
    s.total_quantity DESC, 
    return_rate_percentage DESC;
