
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS day_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_sales_price) AS total_sales,
        day_count + 1
    FROM 
        store_sales
    JOIN sales_summary ON sales_summary.ws_item_sk = store_sales.ss_item_sk
    GROUP BY 
        ss_sold_date_sk, ss_item_sk, day_count
),
top_items AS (
    SELECT 
        i_item_sk,
        i_item_id,
        ROW_NUMBER() OVER (ORDER BY SUM(total_sales) DESC) AS ranking
    FROM 
        sales_summary
    GROUP BY 
        i_item_sk, i_item_id
    HAVING 
        SUM(total_quantity) > 0
)
SELECT 
    ca.city,
    SUM(total_sales) AS sales_total,
    AVG(total_quantity) AS avg_quantity,
    COUNT(DISTINCT t_item_sk) AS unique_item_count
FROM 
    customer_address ca
LEFT JOIN 
    web_sales ws ON ca.ca_address_sk = ws.ws_ship_addr_sk
JOIN 
    sales_summary ss ON ss.ws_item_sk = ws.ws_item_sk
JOIN 
    top_items ti ON ti.i_item_sk = ws.ws_item_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND (ca.ca_state = 'CA' OR ca.ca_state IS NULL)
GROUP BY 
    ca.city
HAVING 
    SUM(total_sales) > 5000
ORDER BY 
    sales_total DESC;
