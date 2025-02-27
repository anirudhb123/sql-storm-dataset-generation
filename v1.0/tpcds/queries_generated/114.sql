
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) as sales_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC, ws.ws_sold_time_sk DESC) as recent_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
),
TotalSales AS (
    SELECT 
        item_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM RankedSales
    WHERE sales_rank = 1
    GROUP BY item_sk
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_return_quantity > 0
    GROUP BY cr_returning_customer_sk
),
CustomerCounts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS sales_count,
        COALESCE(SUM(cr.total_return_amount), 0) AS total_return_amount
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN TotalSales ts ON ss.ss_item_sk = ts.item_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT cc.cr_returning_customer_sk) AS return_count,
    cc.sales_count,
    cc.total_return_amount,
    CASE 
        WHEN cc.sales_count > 0 THEN ROUND((cc.total_return_amount / NULLIF(cc.sales_count, 0)), 2)
        ELSE 0
    END AS avg_return_per_sale
FROM customer c
JOIN CustomerCounts cc ON c.c_customer_sk = cc.c_customer_sk
LEFT JOIN CustomerReturns cr ON cc.total_return_amount > 0
GROUP BY c.c_customer_id, cc.sales_count, cc.total_return_amount
ORDER BY avg_return_per_sale DESC;
