
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_profit) > 0
), top_items AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        s.s_store_name,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM store_sales
    INNER JOIN customer c ON c.c_customer_sk = ss_customer_sk
    INNER JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    INNER JOIN store s ON s.s_store_sk = ss_store_sk
    WHERE ss_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq IN (6, 7)
    )
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, s.s_store_name
), combined_sales AS (
    SELECT 
        ti.c_customer_id,
        ti.c_first_name,
        ti.c_last_name,
        ti.ca_city,
        ti.ca_state,
        ti.s_store_name,
        ti.total_store_sales,
        COALESCE(sc.total_sales, 0) AS web_sales,
        COALESCE(sc.total_profit, 0) AS web_profit
    FROM top_items ti
    LEFT JOIN sales_cte sc ON ti.s_store_name = (
        SELECT s.s_store_name 
        FROM store s
        WHERE s.s_store_sk = (
            SELECT ws.ws_warehouse_sk
            FROM web_sales ws
            WHERE ws.ws_item_sk IN (
                SELECT ws_item_sk FROM sales_cte WHERE sales_rank <= 10
            )
        )
    )
)
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    COALESCE(t.total_store_sales, 0) AS total_store_sales,
    COALESCE(t.web_sales, 0) AS total_web_sales,
    (COALESCE(t.total_store_sales, 0) + COALESCE(t.web_sales, 0)) AS combined_sales,
    CASE 
        WHEN (COALESCE(t.total_store_sales, 0) + COALESCE(t.web_sales, 0)) > 1000 
            THEN 'High Value Customer' 
        ELSE 'Regular Customer' 
    END AS customer_value_segment
FROM customer c
LEFT JOIN combined_sales t ON c.c_customer_id = t.c_customer_id
WHERE c.c_birth_year < 1980
ORDER BY combined_sales DESC
LIMIT 50;
