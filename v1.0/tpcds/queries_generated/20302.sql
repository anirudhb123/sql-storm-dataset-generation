
WITH RECURSIVE address_tree AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_county, ca_state, ca_country
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_address_id, a.ca_city, a.ca_county, a.ca_state, a.ca_country
    FROM customer_address a
    JOIN address_tree t ON a.ca_county = t.ca_county AND a.ca_state = t.ca_state 
    WHERE a.ca_address_sk != t.ca_address_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM((ws.ws_sales_price - ws.ws_ext_discount_amt) * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        MAX(ws.ws_sales_price) AS max_sale_price,
        MIN(ws.ws_sales_price) AS min_sale_price,
        DENSE_RANK() OVER(PARTITION BY c.c_current_cdemo_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_sales,
        cs.total_tax,
        cs.max_sale_price,
        cs.min_sale_price,
        ca.ca_city,
        ca.ca_state
    FROM customer_sales cs
    JOIN address_tree ca ON ca.ca_address_sk = (SELECT MAX(ca_address_sk) FROM customer_address WHERE ca_address_id = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = cs.c_customer_sk))
    WHERE cs.total_orders > 5 AND cs.sales_rank <= 10 -- Adjusting sales rank for performance benchmarking
),
final_analysis AS (
    SELECT 
        tc.c_customer_sk,
        tc.total_sales,
        tc.total_tax,
        tc.max_sale_price,
        tc.min_sale_price,
        COALESCE(MAX(CASE WHEN ws.ws_ship_mode_sk = sm.sm_ship_mode_sk THEN ws.ws_net_paid END), 0) AS highest_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM top_customers tc
    LEFT JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY tc.c_customer_sk, tc.total_sales, tc.total_tax, tc.max_sale_price, tc.min_sale_price
)
SELECT 
    f.c_customer_sk,
    f.total_sales,
    f.total_tax,
    ROUND(f.max_sale_price - f.min_sale_price, 2) AS price_difference,
    f.highest_net_paid,
    CASE 
        WHEN f.highest_net_paid IS NULL THEN 'Null Payment' 
        WHEN f.highest_net_paid < 50 THEN 'Low Payment'
        WHEN f.highest_net_paid BETWEEN 50 AND 150 THEN 'Medium Payment'
        ELSE 'High Payment' 
    END AS payment_category
FROM final_analysis f
WHERE f.total_sales > (SELECT AVG(total_sales) FROM final_analysis) -- Filtering above average sales
ORDER BY f.total_sales DESC;
