
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        c.c_first_name,
        c.c_last_name,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.level + 1
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_current_cdemo_sk = sh.customer_id
),
highest_sales AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
filtered_sales AS (
    SELECT 
        h.customer_id,
        h.total_sales,
        ROW_NUMBER() OVER (PARTITION BY h.customer_id ORDER BY h.total_sales DESC) AS rn
    FROM 
        highest_sales h
    JOIN 
        sales_hierarchy sh ON h.customer_id = sh.customer_id
    WHERE 
        sh.level <= 3
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(ws.ws_net_paid), 0) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    CASE 
        WHEN SUM(ws.ws_net_paid) IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL 
    AND EXISTS (
        SELECT 1 
        FROM filtered_sales fs 
        WHERE fs.customer_id = c.c_customer_sk AND fs.rn = 1
    )
GROUP BY 
    c.c_first_name, 
    c.c_last_name
HAVING 
    total_net_paid > 1000 
    OR sales_status = 'No Sales'
ORDER BY 
    total_net_paid DESC;
