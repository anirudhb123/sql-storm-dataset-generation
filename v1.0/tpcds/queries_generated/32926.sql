
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        c.c_preferred_cust_flag,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price + cs.cs_ext_sales_price + ss.ss_ext_sales_price) DESC) AS rn
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, c.c_preferred_cust_flag
), 
sales_summary AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(cs.total_sales), 0) AS total_customer_sales,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count
    FROM customer_sales cs
    JOIN customer c ON c.c_customer_id = cs.c_customer_id
    WHERE cs.rn = 1
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        total_customer_sales,
        RANK() OVER (ORDER BY total_customer_sales DESC) AS sales_rank
    FROM sales_summary 
    WHERE total_customer_sales > 0
)

SELECT 
    tc.c_customer_id,
    tc.total_customer_sales,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Customer' 
        ELSE 'Regular Customer' 
    END AS customer_category
FROM top_customers tc
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
WHERE cd.cd_gender IS NOT NULL AND cd.cd_marital_status IS NOT NULL;
