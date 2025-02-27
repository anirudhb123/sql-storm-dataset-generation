
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss.sold_date_sk, 
        ss.item_sk, 
        ss.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY ss.sold_date_sk DESC) as rn
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk >= (SELECT MIN(d_date_sk) 
                             FROM date_dim 
                             WHERE d_year = 2022)
),
customer_activity AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id, 
        ca.total_web_sales + ca.total_catalog_sales + ca.total_store_sales AS total_sales,
        DENSE_RANK() OVER (ORDER BY (ca.total_web_sales + ca.total_catalog_sales + ca.total_store_sales) DESC) AS sales_rank
    FROM 
        customer_activity ca
    JOIN customer c ON c.c_customer_id = ca.c_customer_id
    WHERE 
        (ca.total_web_sales + ca.total_catalog_sales + ca.total_store_sales) > 0
)
SELECT 
    t.customer_id, 
    t.total_sales, 
    (SELECT SUM(s.net_profit) 
     FROM sales_cte s 
     WHERE s.rn = 1 
     AND s.sold_date_sk <= (SELECT MAX(d.d_date_sk) 
                             FROM date_dim d 
                             WHERE d_year = 2023)
    ) AS last_year_profit,
    (SELECT STRING_AGG(DISTINCT i.i_item_desc, '; ') 
     FROM item i 
     JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk 
     WHERE ss.ss_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = t.customer_id)
    ) AS purchased_items
FROM 
    top_customers t
WHERE 
    t.sales_rank <= 5
ORDER BY 
    total_sales DESC;
