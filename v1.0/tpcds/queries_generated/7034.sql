
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_sales_price) AS total_spent,
        AVG(ss.ss_sales_price) AS avg_transaction_value,
        COUNT(DISTINCT ss.ss_sold_date_sk) AS shopping_days,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_sales_price) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), TopSpenders AS (
    SELECT 
        customer_id,
        cd_gender,
        cd_marital_status,
        total_transactions,
        total_spent,
        avg_transaction_value,
        shopping_days
    FROM 
        CustomerStats
    WHERE 
        gender_rank <= 10
)
SELECT 
    ts.customer_id,
    ts.cd_gender,
    ts.cd_marital_status,
    ts.total_transactions,
    ts.total_spent,
    ts.avg_transaction_value,
    ts.shopping_days,
    d.d_date AS last_transaction_date
FROM 
    TopSpenders ts
JOIN 
    store_sales ss ON ts.customer_id = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_date = (SELECT MAX(d1.d_date) FROM date_dim d1 WHERE d1.d_date_sk = ss.ss_sold_date_sk)
ORDER BY 
    ts.total_spent DESC;
