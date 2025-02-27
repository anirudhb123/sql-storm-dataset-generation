
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws.web_site_id
), top_sale_websites AS (
    SELECT
        web_site_id,
        total_sales,
        total_orders
    FROM ranked_sales
    WHERE rank_sales <= 10
), customer_sales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_customer_sales,
        COUNT(DISTINCT ws.ws_order_number) AS customer_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
), high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_customer_sales
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_customer_sales >= 1000
), sales_summary AS (
    SELECT 
        tw.web_site_id,
        SUM(hv.total_customer_sales) AS total_sales_from_high_value_customers,
        COUNT(DISTINCT hv.c_customer_id) AS high_value_customer_count
    FROM top_sale_websites tw
    JOIN high_value_customers hv ON tw.web_site_id = hv.c_customer_id 
    GROUP BY tw.web_site_id
)
SELECT 
    s.web_site_id,
    s.total_sales_from_high_value_customers,
    s.high_value_customer_count
FROM sales_summary s
ORDER BY s.total_sales_from_high_value_customers DESC;
