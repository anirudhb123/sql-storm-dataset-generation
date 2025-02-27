
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS distinct_ship_dates
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_current_year = '1'
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.total_net_profit) AS total_net_profit_by_demographics,
        SUM(ss.total_orders) AS total_orders_by_demographics
    FROM 
        SalesSummary AS ss
    JOIN 
        customer_demographics AS cd ON ss.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.total_net_profit_by_demographics,
    d.total_orders_by_demographics,
    RANK() OVER (ORDER BY d.total_net_profit_by_demographics DESC) AS profit_rank
FROM 
    Demographics AS d
ORDER BY 
    profit_rank
LIMIT 10;
