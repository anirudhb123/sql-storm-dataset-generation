
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
), 
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_gender
),
sales_summary AS (
    SELECT 
        c.gender,
        COUNT(cs.c_customer_sk) AS customer_count,
        SUM(cs.total_net_profit) AS total_profit
    FROM customer_sales cs
    JOIN (
        SELECT 
            c_gender,
            COUNT(*) AS customer_count
        FROM customer
        WHERE c_birth_year BETWEEN 1980 AND 1990
        GROUP BY c_gender
    ) AS gender_counts ON gender_counts.c_gender = cs.c_gender
    GROUP BY cs.gender
),
item_summary AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity_sold,
        COALESCE(AVG(ws.ws_net_profit), 0.0) AS average_net_profit
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
)

SELECT 
    ss.gender,
    ss.customer_count,
    ss.total_profit,
    it.i_item_id,
    it.total_quantity_sold,
    it.average_net_profit,
    CASE
        WHEN ss.total_profit > 100000 THEN 'High Profit'
        WHEN ss.total_profit BETWEEN 50000 AND 100000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM sales_summary ss
CROSS JOIN item_summary it
WHERE ss.customer_count > 100
ORDER BY ss.total_profit DESC, it.average_net_profit DESC;
