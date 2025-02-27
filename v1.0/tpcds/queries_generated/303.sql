
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
DateSales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS total_sales_per_date
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales AS customer_sales,
    COALESCE(si.total_store_sales, 0) AS store_sales,
    ds.total_sales_per_date,
    'Above Threshold' AS sales_category
FROM CustomerSales cs
FULL OUTER JOIN StoreInfo si ON cs.c_customer_sk = si.s_store_sk
FULL OUTER JOIN DateSales ds ON ds.total_sales_per_date > 10000
WHERE cs.sales_rank = 1 OR ds.total_sales_per_date IS NOT NULL
ORDER BY cs.total_sales DESC, si.total_store_sales DESC;
