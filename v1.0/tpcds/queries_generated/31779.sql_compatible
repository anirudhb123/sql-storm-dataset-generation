
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        1 AS recursion_level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        sc.recursion_level + 1
    FROM web_sales ws
    JOIN sales_cte sc ON ws.ws_order_number = sc.ws_order_number
    WHERE sc.recursion_level < 5
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        si.ws_item_sk,
        SUM(si.ws_quantity) AS total_quantity,
        SUM(si.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY si.ws_item_sk ORDER BY SUM(si.ws_net_profit) DESC) AS rank_profit
    FROM sales_cte si
    GROUP BY si.ws_item_sk
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_credit_rating,
    cs.cd_purchase_estimate,
    ss.ws_item_sk,
    ss.total_quantity,
    ss.total_profit,
    CASE 
        WHEN ss.rank_profit = 1 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_category
FROM customer_info cs
JOIN sales_summary ss ON cs.c_customer_sk = ss.ws_item_sk
WHERE cs.cd_gender = 'F'
  AND cs.cd_marital_status = 'M'
  AND ss.total_profit IS NOT NULL
ORDER BY ss.total_profit DESC
LIMIT 10 OFFSET 5;
