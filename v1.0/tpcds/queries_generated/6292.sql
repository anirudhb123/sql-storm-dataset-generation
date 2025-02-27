
WITH sales_data AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_id
),
demographics_data AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        COUNT(hd.hd_demo_sk) AS household_count
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    sales_data.c_customer_id,
    sales_data.total_profit,
    sales_data.total_orders,
    sales_data.avg_sales_price,
    demographics_data.avg_vehicle_count,
    demographics_data.household_count
FROM 
    sales_data
JOIN 
    demographics_data ON sales_data.c_customer_id = demographics_data.cd_demo_sk
ORDER BY 
    sales_data.total_profit DESC
LIMIT 10;
