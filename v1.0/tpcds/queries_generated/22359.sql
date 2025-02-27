
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
latest_sales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(*) AS sales_count
    FROM 
        ranked_sales rs
    WHERE 
        rs.rank_sales = 1
    GROUP BY 
        rs.ws_item_sk
),
store_sales_info AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sales_price > (SELECT AVG(ws.ws_sales_price) FROM web_sales ws WHERE ws.ws_item_sk = ss.ss_item_sk)
    GROUP BY 
        ss.ss_item_sk
),
combined_sales AS (
    SELECT 
        l.ws_item_sk,
        COALESCE(l.total_sales, 0) AS web_total,
        COALESCE(s.total_store_sales, 0) AS store_total
    FROM 
        latest_sales l
    FULL OUTER JOIN 
        store_sales_info s ON l.ws_item_sk = s.ss_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.web_total + cs.store_total AS total_combined_sales,
    CASE 
        WHEN cs.web_total > cs.store_total THEN 'Web'
        WHEN cs.store_total > cs.web_total THEN 'Store'
        ELSE 'Equal'
    END AS preferred_channel
FROM 
    customer c
JOIN 
    combined_sales cs ON cs.ws_item_sk IN (
        SELECT 
            cs_item_sk 
        FROM 
            catalog_sales
        WHERE 
            cs_order_number % 2 = 0
    )
WHERE 
    c.c_birth_month = (SELECT DISTINCT d_month_seq FROM date_dim WHERE d_dow = 5 AND d_year = 2023)
    AND c.c_email_address IS NOT NULL
ORDER BY 
    total_combined_sales DESC
FETCH FIRST 100 ROWS ONLY;
