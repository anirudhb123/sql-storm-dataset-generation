
WITH RECURSIVE sales_data AS (
    SELECT 
        ss_store_sk, 
        ss_item_sk, 
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) as sales_rank 
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk, ss_item_sk
), ranked_sales AS (
    SELECT 
        sd.*,
        CASE 
            WHEN total_sales IS NULL THEN 0 
            WHEN total_sales > 1000 THEN 'High'
            WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category 
    FROM 
        sales_data sd
    WHERE 
        sales_rank <= 5
), customer_counts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS transaction_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_sk
), filtered_customers AS (
    SELECT 
        cc.c_customer_sk,
        COALESCE(tc.transaction_count, 0) AS total_transactions
    FROM 
        customer c
    LEFT JOIN 
        customer_counts tc ON c.c_customer_sk = tc.c_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
)
SELECT 
    r.ss_store_sk,
    r.ss_item_sk,
    r.total_sales,
    r.sales_category,
    fc.total_transactions
FROM 
    ranked_sales r
JOIN 
    filtered_customers fc ON r.ss_store_sk = fc.c_customer_sk
WHERE 
    r.total_sales IS NOT NULL
ORDER BY 
    r.total_sales DESC, 
    fc.total_transactions ASC
FETCH FIRST 10 ROWS ONLY;
