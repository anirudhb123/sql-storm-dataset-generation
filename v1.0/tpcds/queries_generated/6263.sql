
WITH customer_purchase_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ss.ss_item_sk) AS unique_items_purchased
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2450000 AND 2450005  -- Example date range
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        c.gender,
        c.marital_status,
        c.total_sales,
        c.total_transactions,
        c.unique_items_purchased,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        customer_purchase_summary c
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.gender,
    tc.marital_status,
    tc.total_sales,
    tc.total_transactions,
    tc.unique_items_purchased
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 10;
