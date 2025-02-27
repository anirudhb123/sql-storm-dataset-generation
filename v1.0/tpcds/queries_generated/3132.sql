
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) 
        AND ws.ws_sold_date_sk <= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
ProfitableCustomers AS (
    SELECT 
        c.customer_id,
        s.total_net_profit,
        s.total_orders,
        s.average_order_value
    FROM 
        SalesSummary s
    JOIN 
        customer c ON s.c_customer_id = c.c_customer_id
    WHERE 
        s.total_net_profit > (SELECT AVG(total_net_profit) FROM SalesSummary)
)

SELECT 
    pc.customer_id,
    pc.total_net_profit,
    pc.total_orders,
    pc.average_order_value,
    CASE 
        WHEN pc.average_order_value > 100 THEN 'High Value Customer'
        WHEN pc.average_order_value BETWEEN 50 AND 100 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category,
    COALESCE(
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk AND ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231),
        0
    ) AS store_purchase_count
FROM 
    ProfitableCustomers pc
JOIN 
    customer c ON pc.customer_id = c.c_customer_id
ORDER BY 
    pc.total_net_profit DESC, pc.total_orders DESC;

