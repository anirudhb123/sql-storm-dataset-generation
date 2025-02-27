
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_sales_price) AS total_sales, 
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2410000 AND 2410600
    GROUP BY 
        ss_store_sk
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            ELSE 'Female'
        END AS gender,
        COUNT(DISTINCT ss_ticket_number) AS num_transactions,
        SUM(ss_sales_price) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss_sales_price) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd_gender
)
SELECT 
    s.ss_store_sk,
    s.total_sales,
    c.total_spent,
    c.gender,
    c.num_transactions,
    COALESCE(c.num_transactions, 0) AS transactions_or_zero
FROM 
    sales_summary s
FULL OUTER JOIN 
    customer_summary c ON s.ss_store_sk = (SELECT DISTINCT sr_store_sk FROM store_returns sr WHERE sr_returned_date_sk = s.ss_sold_date_sk LIMIT 1)
WHERE 
    s.total_sales > 1000 AND s.total_transactions > 5 OR c.total_spent IS NULL
ORDER BY 
    s.total_sales DESC, 
    c.total_spent ASC;
