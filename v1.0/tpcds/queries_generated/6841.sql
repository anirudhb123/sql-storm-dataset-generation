
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_quantity) AS avg_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
        AND ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2022 AND d.d_moy = 12
        )
    GROUP BY 
        c.c_customer_id
), demographic_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        SUM(cs.total_sales) AS total_sales,
        AVG(cs.order_count) AS avg_orders,
        AVG(cs.avg_quantity) AS avg_quantity_per_order,
        AVG(cs.avg_net_profit) AS avg_profit_per_order
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    da.customer_count,
    da.total_sales,
    da.avg_orders,
    da.avg_quantity_per_order,
    da.avg_profit_per_order
FROM 
    demographic_analysis da
JOIN 
    customer_demographics cd ON da.cd_gender = cd.cd_gender
ORDER BY 
    total_sales DESC, customer_count DESC;
