
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq IN (1, 2, 3)
    )
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_sales,
        rs.order_count
    FROM item i
    JOIN ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE rs.sales_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ti.i_item_id,
        ti.i_item_desc,
        ti.total_sales,
        ti.order_count
    FROM customer_info ci
    JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    JOIN top_items ti ON ws.ws_item_sk = ti.ws_item_sk
)
SELECT 
    s.c_customer_id, 
    s.c_first_name, 
    s.c_last_name, 
    s.cd_gender, 
    SUM(s.total_sales) AS total_spent,
    COUNT(s.i_item_id) AS unique_items_purchased
FROM sales_summary s
GROUP BY s.c_customer_id, s.c_first_name, s.c_last_name, s.cd_gender
ORDER BY total_spent DESC
LIMIT 100;
