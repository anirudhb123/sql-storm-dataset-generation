
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_id
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(total_profit) AS avg_profit_per_customer,
        AVG(total_orders) AS avg_orders_per_customer
    FROM 
        SalesSummary ss
    JOIN 
        customer_demographics cd ON ss.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    gender,
    customer_count,
    avg_profit_per_customer,
    avg_orders_per_customer,
    CASE 
        WHEN avg_profit_per_customer > 1000 THEN 'High Value'
        WHEN avg_profit_per_customer > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    DemographicStats
ORDER BY 
    customer_value_segment DESC, customer_count DESC;
