
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE ch.level < 5
),
SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
ProductStats AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        COUNT(DISTINCT sd.ws_sold_date_sk) AS sale_days,
        SUM(sd.total_quantity) AS total_sold_quantity,
        SUM(sd.total_profit) AS total_sold_profit,
        RANK() OVER (ORDER BY SUM(sd.total_profit) DESC) AS profit_rank
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_product_name
),
CustomerSales AS (
    SELECT
        ch.c_first_name,
        ch.c_last_name,
        ps.i_product_name,
        ps.total_sold_quantity,
        ps.total_sold_profit
    FROM CustomerHierarchy ch
    LEFT JOIN store_sales ss ON ch.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN ProductStats ps ON ss.ss_item_sk = ps.i_item_id
    WHERE ch.level = 1 AND ps.profit_rank <= 50
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(cs.total_sold_quantity), 0) AS total_quantity,
    COALESCE(SUM(cs.total_sold_profit), 0) AS total_profit,
    STRING_AGG(DISTINCT ps.i_product_name) AS product_names,
    CASE 
        WHEN SUM(cs.total_sold_profit) IS NULL OR SUM(cs.total_sold_profit) < 0 THEN 'Unprofitable' 
        ELSE 'Profitable' 
    END AS profitability_status
FROM CustomerSales cs
RIGHT JOIN CustomerHierarchy c ON cs.c_first_name = c.c_first_name AND cs.c_last_name = c.c_last_name
GROUP BY c.c_first_name, c.c_last_name
ORDER BY c.c_last_name, c.c_first_name;
