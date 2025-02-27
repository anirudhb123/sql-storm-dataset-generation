
WITH RECURSIVE SalesTree AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        1 AS level,
        ws_sold_date_sk
    FROM 
        web_sales
    WHERE 
        ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
    
    UNION ALL

    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        level + 1,
        cs_sold_date_sk
    FROM 
        catalog_sales
    INNER JOIN SalesTree ON cs_ship_mode_sk = (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR')
    WHERE 
        cs_sales_price < (SELECT SUM(ws_sales_price) FROM web_sales WHERE ws_item_sk = SalesTree.ws_item_sk)
)

SELECT 
    s.ws_item_sk,
    COUNT(DISTINCT s.ws_order_number) AS total_orders,
    SUM(s.ws_sales_price) AS total_sales,
    AVG(s.ws_sales_price) AS avg_sales_per_order,
    RANK() OVER (PARTITION BY s.ws_item_sk ORDER BY SUM(s.ws_sales_price) DESC) AS sales_rank
FROM 
    SalesTree st
JOIN 
    web_sales s ON st.ws_item_sk = s.ws_item_sk
GROUP BY 
    s.ws_item_sk
HAVING 
    COUNT(DISTINCT s.ws_order_number) > (SELECT AVG(order_count) FROM (SELECT COUNT(DISTINCT ws_order_number) AS order_count FROM web_sales GROUP BY ws_item_sk) AS order_counts)
ORDER BY 
    total_sales DESC
LIMIT 10;

SELECT 
    i.i_item_id,
    COALESCE(ss.total_sales, 0) AS store_sales,
    COALESCE(ws.total_sales, 0) AS web_sales
FROM 
    item i
LEFT JOIN (
    SELECT 
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
) ss ON i.i_item_sk = ss.ss_item_sk
LEFT JOIN (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
    GROUP BY 
        ws_item_sk
) ws ON i.i_item_sk = ws.ws_item_sk
WHERE 
    (ss.total_sales IS NOT NULL OR ws.total_sales IS NOT NULL)
    AND (i.i_current_price > 20.00 OR i.i_item_desc LIKE '%special%')
ORDER BY 
    store_sales DESC, web_sales DESC;
