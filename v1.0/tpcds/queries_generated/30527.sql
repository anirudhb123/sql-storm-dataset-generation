
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_sales_price * ws_quantity AS total_sales,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT max(ws_sold_date_sk) FROM web_sales)

    UNION ALL

    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        cs_sales_price * cs_quantity AS total_sales,
        level + 1
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk = (SELECT max(cs_sold_date_sk) FROM catalog_sales)
        AND level < 5
)

SELECT 
    w.ws_order_number AS order_number,
    i.i_item_desc AS item_description,
    SUM(w.ws_net_paid_inc_tax) AS total_web_sales,
    SUM(c.cs_net_paid_inc_tax) AS total_catalog_sales,
    COUNT(DISTINCT w.ws_item_sk) AS distinct_web_items,
    COUNT(DISTINCT c.cs_item_sk) AS distinct_catalog_items,
    CASE 
        WHEN SUM(w.ws_net_paid_inc_tax) > SUM(c.cs_net_paid_inc_tax) THEN 'Web'
        ELSE 'Catalog'
    END AS higher_sales_channel
FROM 
    sales_cte s
LEFT JOIN 
    web_sales w ON s.ws_order_number = w.ws_order_number AND s.ws_item_sk = w.ws_item_sk
LEFT JOIN 
    catalog_sales c ON s.ws_item_sk = c.cs_item_sk
LEFT JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
WHERE 
    w.ws_item_sk IS NOT NULL OR c.cs_item_sk IS NOT NULL
GROUP BY 
    w.ws_order_number, i.i_item_desc
HAVING 
    SUM(w.ws_net_paid_inc_tax) > 1000 OR SUM(c.cs_net_paid_inc_tax) > 1000
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC;

WITH recent_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_birth_year,
        ROW_NUMBER() OVER (PARTITION BY c.c_birth_year ORDER BY c.c_first_shipto_date_sk DESC) AS rn
    FROM 
        customer c
    WHERE 
        c.c_birth_year IS NOT NULL
)
SELECT 
    DISTINCT r.c_customer_id,
    r.c_birth_year
FROM 
    recent_customers r
WHERE 
    r.rn <= 10
ORDER BY 
    r.c_birth_year, r.c_customer_id;
