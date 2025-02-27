WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    CASE 
        WHEN tc.order_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = tc.c_customer_sk 
     AND ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001) 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)) AS store_purchase_count
FROM 
    top_customers tc
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
WHERE 
    tc.sales_rank <= 10
    AND (cd.cd_gender = 'F' OR cd.cd_marital_status IS NULL)
ORDER BY 
    total_sales DESC;