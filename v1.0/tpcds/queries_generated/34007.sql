
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
), 
TopSellingItems AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc, 
        COALESCE(SUM(s.total_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(s.total_revenue), 0) AS total_revenue_generated
    FROM item
    LEFT JOIN SalesCTE s ON item.i_item_sk = s.ws_item_sk
    GROUP BY item.i_item_id, item.i_item_desc
    ORDER BY total_revenue_generated DESC
    LIMIT 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE WHEN ws.net_profit > 0 THEN ws.net_profit ELSE 0 END) AS positive_profit,
        SUM(CASE WHEN ws.net_profit < 0 THEN ws.net_profit ELSE 0 END) AS negative_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_quantity_sold,
    tsi.total_revenue_generated,
    cs.c_customer_id,
    cs.positive_profit,
    cs.negative_profit
FROM TopSellingItems tsi
FULL OUTER JOIN CustomerSales cs ON cs.positive_profit > 0 OR cs.negative_profit < 0
WHERE tsi.total_revenue_generated > 1000
ORDER BY tsi.total_revenue_generated DESC, cs.positive_profit DESC NULLS LAST;
