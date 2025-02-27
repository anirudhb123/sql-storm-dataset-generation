
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        rs.ws_sold_date_sk,
        i.i_item_id,
        i.i_product_name,
        rs.total_quantity,
        rs.total_sales
    FROM ranked_sales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE rs.rank <= 10
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
customer_classification AS (
    SELECT 
        cs.c_customer_sk,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'Gold'
            WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM customer_summary cs
)
SELECT 
    t.ws_sold_date_sk,
    ti.i_item_id,
    ti.i_product_name,
    ti.total_quantity,
    ti.total_sales,
    cc.customer_tier,
    SUM(cs.total_spent) AS aggregate_spent
FROM top_items ti
JOIN customer_classification cc ON ti.ws_sold_date_sk IN (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_item_sk = ti.ws_item_sk)
LEFT JOIN customer_summary cs ON cs.last_purchase_date = ti.ws_sold_date_sk
GROUP BY 
    t.ws_sold_date_sk, 
    ti.i_item_id, 
    ti.i_product_name, 
    cc.customer_tier
ORDER BY 
    t.ws_sold_date_sk, 
    ti.total_sales DESC;
