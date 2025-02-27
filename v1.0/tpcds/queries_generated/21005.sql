
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_net_paid) AS avg_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_city,
        d.d_year,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COALESCE(MAX(ws_net_paid), 0) AS max_spent,
        (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk) AS returns_count,
        CASE 
            WHEN COUNT(DISTINCT ws_order_number) > 5 THEN 'Frequent'
            WHEN COUNT(DISTINCT ws_order_number) BETWEEN 1 AND 5 THEN 'Occasional'
            ELSE 'Rare'
        END AS customer_category
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, c.c_city, d.d_year
),
distinct_inventory AS (
    SELECT DISTINCT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand IS NOT NULL
),
total_inventory AS (
    SELECT 
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM distinct_inventory
)
SELECT 
    cs.c_customer_sk,
    cs.c_city,
    SUM(rs.total_net_paid) AS total_payment,
    cs.order_count,
    cs.max_spent,
    cs.returns_count,
    cs.customer_category,
    COALESCE(inv.total_quantity, 0) AS total_inventory_quantity,
    ROW_NUMBER() OVER (PARTITION BY cs.customer_category ORDER BY total_payment DESC) AS category_rank
FROM customer_summary cs
LEFT JOIN ranked_sales rs ON cs.order_count > 0 AND rs.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = cs.c_customer_sk)
LEFT JOIN total_inventory inv ON TRUE
WHERE cs.max_spent > (SELECT AVG(max_spent) FROM customer_summary) -- only those who spent above average
GROUP BY cs.c_customer_sk, cs.c_city, cs.order_count, cs.max_spent, cs.returns_count, cs.customer_category, inv.total_quantity
HAVING SUM(rs.total_net_paid) IS NOT NULL
ORDER BY cs.customer_category, total_payment DESC;
