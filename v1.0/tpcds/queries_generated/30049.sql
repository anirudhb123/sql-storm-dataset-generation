
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        0 AS level
    FROM 
        customer
    WHERE 
        c_customer_sk IS NOT NULL

    UNION ALL

    SELECT 
        s.ss_customer_sk,
        CONCAT(s.c_first_name, ' - Order #', s.ss_ticket_number) AS c_first_name,
        c_last_name,
        level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_customer_sk = sh.c_customer_sk
)
SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    COUNT(s.ss_ticket_number) AS order_count,
    SUM(s.ss_sales_price) AS total_sales,
    MAX(s.ss_sold_date_sk) AS last_order_date,
    ROW_NUMBER() OVER (PARTITION BY sh.c_customer_sk ORDER BY SUM(s.ss_sales_price) DESC) AS sales_rank
FROM 
    sales_hierarchy sh
LEFT JOIN 
    store_sales s ON sh.c_customer_sk = s.ss_customer_sk
GROUP BY 
    sh.c_customer_sk, sh.c_first_name, sh.c_last_name
HAVING 
    SUM(s.ss_sales_price) IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 10;

-- Additional independent query for benchmarking
SELECT 
    w.w_warehouse_id,
    SUM(ws.ws_quantity) AS total_quantity,
    MAX(ws.ws_sales_price) AS max_sales_price,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    (SELECT COUNT(DISTINCT wr_refunded_customer_sk) FROM web_returns wr WHERE wr.wr_web_page_sk IN (SELECT wp_web_page_sk FROM web_page)) AS total_web_returns
FROM 
    web_sales ws
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    w.w_warehouse_id
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    total_quantity DESC;
