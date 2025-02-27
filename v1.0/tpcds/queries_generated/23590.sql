
WITH RECURSIVE sales_data AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL 
        AND (c.c_birth_month IS NULL OR c.c_birth_month BETWEEN 5 AND 8)
    GROUP BY 
        c.c_customer_id
),
top_sales AS (
    SELECT 
        customer_id, 
        total_sales, 
        order_count
    FROM 
        sales_data
    WHERE 
        rn <= 5
)
SELECT 
    ts.customer_id,
    ts.total_sales,
    COALESCE(st.store_name, 'N/A') AS store_name,
    CASE 
        WHEN ts.order_count > 10 THEN 'High'
        WHEN ts.order_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    top_sales ts
LEFT JOIN 
    store st ON EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = ts.customer_id)
        AND ss.ss_store_sk = st.s_store_sk
    )
ORDER BY 
    ts.total_sales DESC
LIMIT 10
UNION ALL
SELECT 
    'TOTAL' AS customer_id, 
    SUM(total_sales) AS total_sales, 
    NULL AS store_name, 
    NULL AS sales_category
FROM 
    top_sales
WHERE 
    total_sales IS NOT NULL
HAVING 
    SUM(total_sales) > (SELECT AVG(total_sales) FROM top_sales);
