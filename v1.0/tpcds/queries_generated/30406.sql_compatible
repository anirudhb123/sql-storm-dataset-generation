
WITH RECURSIVE sale_summary AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS num_transactions,
        MIN(ss_sold_date_sk) AS first_sale_date,
        MAX(ss_sold_date_sk) AS last_sale_date
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
), 
customer_summary AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        COUNT(ss_peremption) AS total_purchases,
        MAX(ss_amount) AS max_transaction,
        AVG(ss_amount) AS avg_transaction
    FROM 
        customer 
    LEFT JOIN 
        store_sales ON store_sales.ss_customer_sk = customer.c_customer_sk
    LEFT JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        c_customer_sk, cd_gender, cd_marital_status
), 
sales_analysis AS (
    SELECT 
        ss_store_sk,
        total_sales,
        num_transactions,
        first_sale_date,
        last_sale_date,
        DATEDIFF(last_sale_date, first_sale_date) AS sale_duration,
        (CASE WHEN MAX(total_sales) OVER () > 0 THEN total_sales / MAX(total_sales) OVER () END) AS sales_percentage
    FROM 
        sale_summary
)
SELECT 
    s.ss_store_sk,
    s.total_sales,
    s.num_transactions,
    CASE
        WHEN s.sale_duration < 30 THEN 'New'
        WHEN s.sale_duration BETWEEN 30 AND 90 THEN 'Regular'
        ELSE 'Loyal'
    END AS customer_type,
    (SELECT COUNT(DISTINCT c_customer_sk) FROM customer_summary WHERE total_purchases > 5) AS high_purchasing_customers,
    (SELECT cd_gender FROM customer_summary WHERE c_customer_sk = 
        (SELECT c_customer_sk 
         FROM customer_summary 
         ORDER BY max_transaction DESC 
         LIMIT 1)
    ) AS gender_of_top_customer
FROM 
    sales_analysis s
LEFT JOIN 
    store ON s.ss_store_sk = store.s_store_sk
WHERE 
    s.total_sales IS NOT NULL
ORDER BY 
    s.total_sales DESC
LIMIT 100;
