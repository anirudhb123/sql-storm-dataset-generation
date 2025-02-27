
WITH RECURSIVE sales_hierarchy AS (
    SELECT cs_item_sk, SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    GROUP BY cs_item_sk
    HAVING SUM(cs_net_profit) > 1000
    UNION ALL
    SELECT cs.cs_item_sk, sh.total_profit + SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN sales_hierarchy sh ON cs.cs_item_sk = sh.cs_item_sk
    GROUP BY cs.cs_item_sk, sh.total_profit
),
ranked_sales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sh.total_profit,
        RANK() OVER (ORDER BY sh.total_profit DESC) AS profit_rank
    FROM sales_hierarchy sh
    JOIN item i ON sh.cs_item_sk = i.i_item_sk
    WHERE sh.total_profit IS NOT NULL
),
top_sales AS (
    SELECT *
    FROM ranked_sales
    WHERE profit_rank <= 10
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, cd.cd_purchase_estimate
),
final_sales_summary AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_credit_rating,
        cs.cd_purchase_estimate,
        ts.i_item_desc,
        ts.total_profit,
        COALESCE(ts.total_orders, 0) AS total_orders
    FROM customer_details cs
    FULL OUTER JOIN top_sales ts ON cs.c_customer_id IS NOT NULL
)
SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_credit_rating,
    f.cd_purchase_estimate,
    f.i_item_desc,
    f.total_profit,
    f.total_orders,
    CASE 
        WHEN f.total_profit IS NULL THEN 'Not Applicable'
        WHEN f.total_profit < 5000 THEN 'Low Profit'
        WHEN f.total_profit BETWEEN 5000 AND 15000 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM final_sales_summary f
WHERE f.total_profit IS NOT NULL
ORDER BY f.total_profit DESC
LIMIT 50;
