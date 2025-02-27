
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales
    FROM
        sales_hierarchy sh
    JOIN customer c ON c.c_current_cdemo_sk = sh.c_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_sales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_sales,
        RANK() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
    FROM 
        sales_hierarchy sh
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_sales,
    CASE 
        WHEN r.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales'
    END AS sales_status,
    d.d_year,
    w.w_country
FROM 
    ranked_sales r
LEFT JOIN date_dim d ON d.d_date_sk = 
    (SELECT 
        MAX(ws.ws_sold_date_sk) 
     FROM 
        web_sales ws 
     WHERE 
        ws.ws_ship_customer_sk = r.c_customer_sk)
LEFT JOIN warehouse w ON w.w_warehouse_sk = 
    (SELECT 
        ws.ws_warehouse_sk 
     FROM 
        web_sales ws 
     WHERE 
        ws.ws_ship_customer_sk = r.c_customer_sk 
     ORDER BY ws.ws_sold_date_sk DESC 
     LIMIT 1)
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;
