
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY 
        ss_store_sk
),
top_stores AS (
    SELECT 
        store.s_store_name,
        sales.total_sales,
        sales.total_transactions,
        DENSE_RANK() OVER (ORDER BY sales.total_sales DESC) AS sales_rank
    FROM 
        sales_cte sales
    JOIN 
        store store ON sales.ss_store_sk = store.s_store_sk
    WHERE 
        sales.rank <= 10
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS orders_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
aggregated_sales AS (
    SELECT 
        c.c_customer_id,
        cs.orders_count,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent IS NULL THEN 'No Purchases'
            WHEN cs.total_spent < 100 THEN 'Low Spender'
            WHEN cs.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
            ELSE 'High Spender'
        END AS spender_category
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
),
final_report AS (
    SELECT 
        ts.store_name,
        AVG(as.total_spent) AS avg_spent,
        COUNT(as.c_customer_id) AS customer_count,
        SUM(CASE WHEN as.spender_category = 'High Spender' THEN 1 ELSE 0 END) AS high_spenders_count
    FROM 
        top_stores ts
    LEFT JOIN 
        aggregated_sales as ON ts.store_name = as.c_customer_id
    GROUP BY 
        ts.store_name
)
SELECT 
    fr.store_name,
    fr.avg_spent,
    fr.customer_count,
    fr.high_spenders_count
FROM 
    final_report fr
ORDER BY 
    fr.avg_spent DESC;
