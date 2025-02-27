
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
high_demand_items AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        CASE 
            WHEN r.total_sales > 1000 THEN 'High Seller'
            WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Medium Seller'
            ELSE 'Low Seller'
        END AS sales_category
    FROM ranked_sales r
    WHERE r.sales_rank <= 10
),
customer_preferences AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT w.ws_order_number) AS order_count,
        MAX(w.ws_net_paid) AS max_spent
    FROM customer c
    LEFT JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
promotions_data AS (
    SELECT 
        p.p_promo_id,
        COUNT(*) AS usage_count
    FROM promotion p
    INNER JOIN web_sales w ON p.p_promo_sk = w.ws_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id
)
SELECT 
    ca.ca_city,
    SUM(ws_quantity) AS total_quantity_sold,
    AVG(ws_ext_sales_price) AS avg_price,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    COUNT(DISTINCT p.p_promo_id) AS total_promotions_used,
    (SELECT COUNT(*) FROM customer_preferences cp WHERE cp.max_spent > 200) AS high_spenders_count,
    (SELECT COUNT(*) FROM high_demand_items hdi WHERE hdi.sales_category = 'High Seller') AS high_demand_count
FROM customer_address ca
JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
LEFT JOIN promotions_data p ON p.promo_id IN (SELECT DISTINCT wp.web_site_sk FROM web_page wp WHERE wp.wp_access_date_sk = w.ws_sold_date_sk)
WHERE ca.ca_state = 'CA'
  AND ws_sold_date_sk BETWEEN 20220101 AND 20220131
  AND ws_quantity IS NOT NULL
GROUP BY ca.ca_city
HAVING SUM(ws_quantity) > 5000 OR avg_price < 10
ORDER BY total_quantity_sold DESC, avg_price ASC
LIMIT 20;
