
WITH sales_data AS (
    SELECT 
        s_store_sk, 
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        s_store_sk
), 
top_stores AS (
    SELECT 
        s_store_sk, 
        total_quantity, 
        total_profit, 
        unique_customers,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        sales_data
),
customer_segments AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS num_customers,
        SUM(CASE WHEN c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    ts.s_store_sk,
    ts.total_quantity,
    ts.total_profit,
    ts.unique_customers,
    cs.cd_gender,
    cs.num_customers,
    cs.preferred_count
FROM 
    top_stores ts
JOIN 
    customer_segments cs ON ts.s_store_sk IN (SELECT DISTINCT ss_store_sk FROM store_sales WHERE ss_customer_sk IN (SELECT c_customer_sk FROM customer))
WHERE 
    ts.profit_rank <= 10
ORDER BY 
    ts.total_profit DESC;
