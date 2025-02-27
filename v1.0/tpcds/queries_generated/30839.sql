
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_id,
        p.p_end_date_sk,
        p.p_start_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_sk, p.p_promo_id, p.p_end_date_sk, p.p_start_date_sk
),
Customer_Order AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name
),
Top_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.total_store_sales + c.total_web_sales AS total_spent,
        RANK() OVER (ORDER BY (c.total_store_sales + c.total_web_sales) DESC) AS customer_rank
    FROM Customer_Order c
    WHERE (c.total_store_sales + c.total_web_sales) > 500 
),
Address_Stats AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        COUNT(DISTINCT hs.hd_income_band_sk) AS distinct_income_bands
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY ca.ca_state
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    COALESCE(a.customer_count, 0) AS customer_count,
    COALESCE(a.avg_vehicle_count, 0) AS average_vehicle_count,
    COALESCE(p.promo_sales_count, 0) AS promo_sales_count,
    s.total_sales AS total_sales,
    COUNT(DISTINCT s.ws_order_number) AS order_count
FROM Top_Customers tc
LEFT JOIN Address_Stats a ON a.customer_count > 0
LEFT JOIN Promotions p ON p.promo_sales_count > 0
JOIN Sales_CTE s ON tc.c_customer_sk = s.ws_item_sk
WHERE s.rank <= 10 OR p.promo_sales_count IS NOT NULL
GROUP BY tc.c_customer_sk, tc.c_first_name, a.customer_count, a.avg_vehicle_count, p.promo_sales_count, s.total_sales
ORDER BY total_sales DESC;
