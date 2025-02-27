
WITH RECURSIVE date_range AS (
    SELECT MIN(d_date_sk) AS date_sk FROM date_dim
    UNION ALL
    SELECT date_sk + 1 FROM date_range WHERE date_sk < (SELECT MAX(d_date_sk) FROM date_dim)
),
sales_data AS (
    SELECT
        d.d_date,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
ranked_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS gender_rank
    FROM customer_stats cs
),
inventory_levels AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    dr.date_sk,
    dr.total_net_paid,
    dr.total_quantity,
    rc.c_customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_spent,
    rc.order_count,
    COALESCE(il.total_quantity_on_hand, 0) AS total_quantity_on_hand,
    CASE 
        WHEN dr.total_net_paid IS NULL THEN 'No Sales'
        WHEN dr.total_net_paid > 10000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM date_range dr
LEFT JOIN sales_data dr ON dr.date_sk = dr.d_date
LEFT JOIN ranked_customers rc ON rc.order_count > 0
LEFT JOIN inventory_levels il ON il.inv_item_sk = (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = dr.date_sk
    LIMIT 1
)
WHERE rc.gender_rank <= 5
ORDER BY dr.date_sk DESC, rc.total_spent DESC;
