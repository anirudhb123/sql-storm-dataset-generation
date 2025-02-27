
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_net_paid,
        cs.total_orders
    FROM 
        customer_demographics cd
    JOIN 
        customer_sales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
average_sales AS (
    SELECT 
        cd.cd_gender,
        AVG(cs.total_net_paid) AS avg_net_paid,
        AVG(cs.total_orders) AS avg_orders
    FROM 
        customer_info cs
    GROUP BY 
        cd.cd_gender
)
SELECT 
    a.cd_gender,
    a.avg_net_paid,
    a.avg_orders,
    CASE 
        WHEN a.avg_net_paid > 1000 THEN 'High Value'
        WHEN a.avg_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    average_sales a
ORDER BY 
    a.avg_net_paid DESC;
