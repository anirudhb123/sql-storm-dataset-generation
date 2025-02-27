
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count,
        AVG(ss.ss_quantity) AS average_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
demographics_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        SUM(cs.total_net_profit) AS net_profit_sum,
        AVG(cs.average_quantity) AS average_quantity_sold
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
warehouse_analysis AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        warehouse w
    JOIN 
        store s ON w.w_warehouse_sk = s.s_store_sk
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.customer_count,
    da.net_profit_sum,
    wa.total_profit,
    wa.total_transactions
FROM 
    demographics_analysis da
JOIN 
    warehouse_analysis wa ON da.customer_count > 100
ORDER BY 
    da.net_profit_sum DESC, wa.total_profit DESC
LIMIT 10;
