
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2452108 AND 2452148

    UNION ALL

    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        level + 1
    FROM web_sales ws
    INNER JOIN SalesCTE s ON ws.ws_sold_date_sk = s.ws_sold_date_sk AND ws.ws_item_sk = s.ws_item_sk
    WHERE s.level < 5
),
CustomerProfit AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
HighProfitCustomers AS (
    SELECT c.c_customer_id
    FROM CustomerProfit c
    WHERE c.total_profit > (SELECT AVG(total_profit) FROM CustomerProfit)
),
SalesByCustomer AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT(ws.ws_order_number)) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
    HAVING c.c_customer_id IN (SELECT c.c_customer_id FROM HighProfitCustomers)
)
SELECT 
    sbc.c_customer_id,
    sbc.total_quantity,
    sbc.total_profit,
    CASE 
        WHEN sbc.order_count > 10 THEN 'High Engagement'
        WHEN sbc.order_count BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS engagement_level,
    DENSE_RANK() OVER (ORDER BY sbc.total_profit DESC) AS profit_rank
FROM SalesByCustomer sbc
ORDER BY sbc.total_profit DESC
LIMIT 10;
