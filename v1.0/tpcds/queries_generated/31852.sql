
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_name, s_number_employees, s_sales AS total_sales
    FROM store
    WHERE s_number_employees IS NOT NULL
    UNION ALL
    SELECT s_store_sk, s_store_name, s_number_employees, s_sales + COALESCE(total_sales, 0)
    FROM store s
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
),
sales_summary AS (
    SELECT 
        ca_city,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        MAX(ws_sold_date_sk) AS last_web_sale_date
    FROM web_sales ws
    LEFT JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca_city
),
top_sales AS (
    SELECT 
        ca_city,
        RANK() OVER (ORDER BY total_web_sales DESC) AS city_rank,
        total_web_sales,
        total_store_sales,
        total_orders,
        last_web_sale_date
    FROM sales_summary
    WHERE total_web_sales IS NOT NULL
)
SELECT
    ca_city,
    total_web_sales,
    total_store_sales,
    total_orders,
    last_web_sale_date,
    COALESCE(total_web_sales + total_store_sales, 0) AS combined_sales,
    CASE 
        WHEN total_web_sales > 0 THEN 'Web Sales Dominant'
        WHEN total_store_sales > 0 THEN 'Store Sales Dominant'
        ELSE 'No Sales'
    END AS sales_category
FROM top_sales
WHERE city_rank <= 10
ORDER BY total_web_sales DESC, ca_city;
