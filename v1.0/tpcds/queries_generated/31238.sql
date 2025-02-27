
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        cs.s_order_number, 
        cs.cs_item_sk, 
        cs.cs_sales_price, 
        cs.cs_quantity,
        1 AS level,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sales_price DESC) AS rank
    FROM 
        catalog_sales cs
    JOIN 
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE 
        cs.cs_sales_price > 50
    UNION ALL
    SELECT 
        ss.s_order_number, 
        ss.ss_item_sk, 
        ss.ss_sales_price, 
        ss.ss_quantity,
        h.level + 1,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sales_price DESC) AS rank
    FROM 
        store_sales ss
    JOIN 
        SalesHierarchy h ON ss.ss_item_sk = h.cs_item_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        h.level < 3
)
SELECT 
    sh.c_customer_id,
    sh.c_first_name,
    sh.c_last_name,
    SUM(sh.cs_sales_price * sh.cs_quantity) AS total_sales,
    AVG(sh.cs_sales_price) AS avg_sales_price,
    (SELECT COUNT(*) FROM store WHERE s_tax_precentage IS NOT NULL) AS store_count,
    CASE 
        WHEN SUM(sh.cs_sales_price) > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value,
    COALESCE(MAX(sh.rank), 0) AS max_rank
FROM 
    SalesHierarchy sh
GROUP BY 
    sh.c_customer_id, sh.c_first_name, sh.c_last_name
HAVING 
    total_sales > 200
ORDER BY 
    total_sales DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
