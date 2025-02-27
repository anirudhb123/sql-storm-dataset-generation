
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_year,
        1 AS hierarchy_level
    FROM 
        customer
    WHERE 
        c_birth_year IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ch.hierarchy_level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON ch.c_customer_sk = c.c_current_cdemo_sk
)
, SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.c_birth_year,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.avg_order_value, 0) AS avg_order_value,
    ROW_NUMBER() OVER (PARTITION BY ch.hierarchy_level ORDER BY COALESCE(ss.total_profit, 0) DESC) AS rank_by_profit
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    SalesSummary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ch.hierarchy_level < 3
ORDER BY 
    ch.hierarchy_level, rank_by_profit;

