
WITH ranked_sales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS store_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ss_store_sk
),
top_stores AS (
    SELECT 
        ss_store_sk,
        total_profit,
        transaction_count
    FROM 
        ranked_sales
    WHERE 
        store_rank <= 10
),
customer_stats AS (
    SELECT 
        c_customer_sk,
        SUM(ss_net_profit) AS customer_profit,
        COUNT(ss_ticket_number) AS customer_transactions
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        ss.ss_store_sk IN (SELECT ss_store_sk FROM top_stores)
    GROUP BY 
        c_customer_sk
)
SELECT 
    s.s_store_name,
    cs.customer_profit AS total_customer_profit,
    cs.customer_transactions AS total_customer_transactions,
    ts.total_profit AS store_total_profit,
    ts.transaction_count AS store_transaction_count,
    ts.total_profit / NULLIF(ts.transaction_count, 0) AS avg_profit_per_transaction
FROM 
    top_stores ts
JOIN 
    store s ON ts.ss_store_sk = s.s_store_sk
JOIN 
    customer_stats cs ON ts.ss_store_sk IN (SELECT ss_store_sk FROM store_sales WHERE ss_customer_sk = cs.c_customer_sk)
ORDER BY 
    store_total_profit DESC;
