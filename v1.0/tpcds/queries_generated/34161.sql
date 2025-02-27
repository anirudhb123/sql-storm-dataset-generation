
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_profit) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
sales_threshold AS (
    SELECT 
        total_sales, 
        total_transactions 
    FROM 
        sales_summary 
    WHERE 
        rank = 1
), 
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MAX(cd.cd_credit_rating) AS credit_rating
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cd.gender,
    cd.max_purchase_estimate,
    cd.credit_rating,
    COALESCE(st.total_sales, 0) AS highest_sales,
    COALESCE(st.total_transactions, 0) AS transaction_count
FROM 
    sales_summary cs
LEFT JOIN 
    sales_threshold st ON cs.total_sales = st.total_sales
LEFT JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    COALESCE(st.total_sales, 0) > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    highest_sales DESC
LIMIT 100;
