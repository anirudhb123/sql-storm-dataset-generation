
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
        AND d.d_moy IN (11, 12)  -- focusing on the last two months of the year
    GROUP BY 
        w.w_warehouse_id,
        c.c_customer_id
), 
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(ss.total_orders) AS orders_count,
        AVG(ss.total_net_profit) AS avg_net_profit_per_customer
    FROM 
        customer_demographics cd
    JOIN 
        sales_summary ss ON cd.cd_demo_sk IN (
            SELECT 
                c.c_current_cdemo_sk 
            FROM 
                customer c 
            WHERE 
                c.c_customer_id = ss.c_customer_id
        )
    GROUP BY 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(*) AS demographic_count,
    SUM(cd.orders_count) AS total_orders,
    AVG(cd.avg_net_profit_per_customer) AS average_net_profit
FROM 
    customer_demographics cd
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
ORDER BY 
    total_orders DESC
LIMIT 10;
