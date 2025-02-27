
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales IS NOT NULL
), 
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
), 
sales_by_gender AS (
    SELECT 
        c.cd_gender,
        COUNT(DISTINCT hvc.c_customer_sk) AS customer_count,
        SUM(hvc.total_sales) AS total_sales
    FROM 
        high_value_customers hvc
    JOIN 
        customer_demographics c ON hvc.c_customer_sk = c.cd_demo_sk
    GROUP BY 
        c.cd_gender
)
SELECT 
    sbg.cd_gender,
    sbg.customer_count,
    sbg.total_sales,
    ROUND((sbg.total_sales / NULLIF((SELECT SUM(total_sales) FROM sales_by_gender), 0)) * 100, 2) AS percentage_of_total_sales,
    CASE 
        WHEN sbg.total_sales > 1000 THEN 'High Spender' 
        ELSE 'Low Spender' 
    END AS spender_type
FROM 
    sales_by_gender sbg
ORDER BY 
    sbg.total_sales DESC;
