
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
    UNION ALL
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) + c.total_quantity,
        SUM(s.ss_ext_sales_price) + c.total_sales
    FROM 
        store_sales s
    JOIN 
        sales_cte c ON s.ss_item_sk = c.ss_item_sk
    WHERE 
        s.ss_sold_date_sk > c.ss_sold_date_sk
    GROUP BY 
        s.ss_sold_date_sk, s.ss_item_sk
), 
customer_sales AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        c.cc_call_center_sk,
        COALESCE(SUM(ws_ext_sales_price), 0) AS web_sales_amount,
        COALESCE(SUM(cs_ext_sales_price), 0) AS catalog_sales_amount,
        COALESCE(SUM(ss_ext_sales_price), 0) AS store_sales_amount,
        COALESCE(MAX(ws_ext_sales_price), 0) AS max_web_sale,
        COALESCE(MAX(cs_ext_sales_price), 0) AS max_catalog_sale,
        COALESCE(MAX(ss_ext_sales_price), 0) AS max_store_sale
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_first_name, c.c_last_name, c.cc_call_center_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cc_call_center_sk,
    LEAD(cs.web_sales_amount) OVER (PARTITION BY cs.cc_call_center_sk ORDER BY cs.web_sales_amount DESC) AS next_web_sales,
    cs.web_sales_amount,
    cs.catalog_sales_amount,
    cs.store_sales_amount,
    CASE WHEN cs.web_sales_amount > cs.catalog_sales_amount THEN 'Web Leader'
         ELSE 'Catalog Leader' END AS Sales_Leader
FROM 
    customer_sales cs
WHERE 
    cs.web_sales_amount > 0 OR 
    cs.catalog_sales_amount > 0 OR 
    cs.store_sales_amount > 0
ORDER BY 
    cs.web_sales_amount DESC, cs.catalog_sales_amount DESC;
