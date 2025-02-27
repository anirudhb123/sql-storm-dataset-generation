
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 10
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
), top_customers AS (
    SELECT 
        c.customer_id,
        ci.total_spent,
        ci.order_count,
        ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY ci.total_spent DESC) AS gender_rank
    FROM customer c
    JOIN customer_info ci ON c.c_customer_sk = ci.c_customer_sk
), low_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_net_profit
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
    HAVING SUM(ss_quantity) < 5
), combined AS (
    SELECT 
        tc.customer_id,
        ts.item_id,
        tc.total_spent,
        ts.total_quantity,
        ts.total_net_profit
    FROM top_customers tc
    JOIN low_sales ts ON ts.total_quantity < 5
)
SELECT 
    coalesce(tc.customer_id, 'No Customer') AS customer_id,
    ts.item_id AS item_id,
    tc.total_spent,
    ts.total_quantity,
    ts.total_net_profit,
    CASE 
        WHEN ts.total_net_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status,
    GREATEST(IFNULL(tc.order_count, 0), 0) AS valid_order_count,
    RANK() OVER (ORDER BY ts.total_net_profit DESC) AS sales_rank
FROM combined
FULL OUTER JOIN top_customers tc ON tc.gender_rank = 1
LEFT JOIN low_sales ts ON ts.total_quantity < 5
ORDER BY tc.total_spent DESC, ts.total_net_profit ASC;
