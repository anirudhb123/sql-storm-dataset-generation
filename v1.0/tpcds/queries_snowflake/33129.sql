
WITH RECURSIVE sales_trends AS (
    SELECT 
        w.w_warehouse_sk,
        s.s_store_sk,
        COALESCE(ws_ext_sales_price, 0) AS total_sales,
        ws_sold_date_sk,
        1 AS sales_rank
    FROM 
        warehouse w
    LEFT JOIN store s ON w.w_warehouse_sk = s.s_store_sk
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        
    UNION ALL
    
    SELECT 
        st.w_warehouse_sk,
        st.s_store_sk,
        COALESCE(st.total_sales + 
            (SELECT ws_ext_sales_price 
             FROM web_sales 
             WHERE ws_ship_addr_sk = st.s_store_sk AND ws_sold_date_sk < st.ws_sold_date_sk 
             ORDER BY ws_sold_date_sk DESC LIMIT 1), 0),
        (SELECT ws_sold_date_sk 
         FROM web_sales 
         WHERE ws_ship_addr_sk = st.s_store_sk AND ws_sold_date_sk < st.ws_sold_date_sk 
         ORDER BY ws_sold_date_sk DESC LIMIT 1),
        sales_rank + 1
    FROM 
        sales_trends st
    WHERE 
        st.ws_sold_date_sk > (SELECT MIN(ws_sold_date_sk) FROM web_sales WHERE ws_ship_addr_sk = st.s_store_sk)
),
total_sales_by_category AS (
    SELECT 
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_category_sales
    FROM 
        web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_category
),
top_categories AS (
    SELECT 
        i_category,
        total_category_sales,
        ROW_NUMBER() OVER (ORDER BY total_category_sales DESC) AS category_rank
    FROM 
        total_sales_by_category
)
SELECT 
    a.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(s.total_sales) AS warehouse_sales,
    LISTAGG(DISTINCT tc.i_category, ', ') AS top_categories
FROM 
    customer c
LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN sales_trends s ON c.c_customer_sk = s.s_store_sk
JOIN top_categories tc ON s.s_store_sk = tc.category_rank
WHERE 
    a.ca_state = 'CA'
    AND (s.total_sales IS NOT NULL AND s.total_sales > 0)
GROUP BY 
    a.ca_city, s.total_sales, tc.category_rank
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    warehouse_sales DESC;
