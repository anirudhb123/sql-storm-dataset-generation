
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        ws.ws_sales_price,
        COALESCE(ws.ws_coupon_amt, 0) AS coupon_amount,
        ws.ws_quantity,
        (ws.ws_sales_price - COALESCE(ws.ws_ext_discount_amt, 0)) * ws.ws_quantity AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_moy IN (1, 2)
    )
),
customer_metrics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(total_sales, 0)) AS total_spent,
        AVG(total_sales) AS avg_spent,
        COUNT(DISTINCT sales_rank) AS unique_items_purchased
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN ranked_sales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
summary_stats AS (
    SELECT
        cd.gender,
        cd.marital_status,
        COUNT(DISTINCT c.customer_id) AS customer_count,
        SUM(cm.total_spent) AS total_spending,
        SUM(cm.avg_spent) AS overall_avg_spent,
        MAX(cm.total_spent) AS max_spent,
        MIN(cm.total_spent) AS min_spent
    FROM customer_metrics cm
    JOIN customer c ON cm.c_customer_id = c.c_customer_id
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.gender, cd.marital_status
)
SELECT
    gender,
    marital_status,
    customer_count,
    total_spending,
    overall_avg_spent,
    (total_spending / NULLIF(customer_count, 0)) AS avg_spending_per_customer,
    CASE 
        WHEN max_spent > 1000 THEN 'High Spender'
        WHEN max_spent BETWEEN 500 AND 1000 THEN 'Mid Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM summary_stats
WHERE total_spending IS NOT NULL
ORDER BY total_spending DESC
LIMIT 10;
