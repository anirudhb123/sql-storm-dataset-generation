
WITH sales_summary AS (
    SELECT 
        d.d_year,
        c.c_gender,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        d.d_year, c.c_gender
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_net_paid) AS avg_net_paid
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
combined_summary AS (
    SELECT 
        ss.d_year,
        ss.c_gender,
        ws.w_warehouse_id,
        ss.total_profit,
        ss.unique_customers,
        ss.avg_sales_price,
        ss.total_transactions,
        ws.total_quantity,
        ws.avg_net_paid
    FROM 
        sales_summary ss
    JOIN 
        warehouse_summary ws ON ss.d_year = 2022
)
SELECT 
    d_year, 
    c_gender,
    w_warehouse_id, 
    total_profit, 
    unique_customers, 
    avg_sales_price, 
    total_transactions, 
    total_quantity, 
    avg_net_paid
FROM 
    combined_summary
ORDER BY 
    total_profit DESC, 
    unique_customers DESC;
