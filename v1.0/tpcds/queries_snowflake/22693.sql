
WITH RECURSIVE sales_ranks AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank,
        ws_net_profit
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
), 
agg_sales AS (
    SELECT 
        c_customer_sk,
        SUM(ws_net_paid) AS total_paid,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    LEFT JOIN customer ON ws_bill_customer_sk = c_customer_sk
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_dow IN (1, 2, 3, 4, 5)
    )
    GROUP BY c_customer_sk
),
filtered_customers AS (
    SELECT 
        a.c_customer_sk,
        COALESCE(a.total_paid, 0) AS total_paid,
        CASE 
            WHEN a.order_count > 0 THEN 'active' 
            ELSE 'inactive' 
        END AS customer_status 
    FROM agg_sales a
    LEFT JOIN customer_demographics b ON a.c_customer_sk = b.cd_demo_sk
    WHERE b.cd_marital_status = 'M' AND b.cd_gender = 'F'
),
max_profit AS (
    SELECT 
        ws_item_sk, 
        MAX(ws_net_profit) AS max_profit_value
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT 
    fc.c_customer_sk,
    fc.total_paid,
    fc.customer_status,
    LISTAGG(CONCAT_WS(' - ', CAST(sr.rank AS VARCHAR), sr.ws_order_number, sr.ws_net_profit), ', ') WITHIN GROUP (ORDER BY sr.rank) AS ranked_sales,
    mp.max_profit_value
FROM filtered_customers fc
LEFT JOIN sales_ranks sr ON fc.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_order_number = sr.ws_order_number LIMIT 1)
LEFT JOIN max_profit mp ON sr.ws_item_sk = mp.ws_item_sk
WHERE fc.total_paid > (SELECT AVG(total_paid) FROM filtered_customers) 
  OR fc.customer_status = 'active'
GROUP BY fc.c_customer_sk, fc.total_paid, fc.customer_status, mp.max_profit_value
HAVING COUNT(sr.ws_order_number) > 2
ORDER BY fc.total_paid DESC, fc.customer_status ASC;
