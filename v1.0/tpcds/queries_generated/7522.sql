
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_quantity) AS average_order_quantity,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023  -- Filter for the year 2023
    GROUP BY 
        c.c_customer_id
),
DemographicsSummary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT ss.c_customer_id) AS customer_count,
        SUM(ss.total_net_profit) AS total_net_profit,
        AVG(ss.average_order_quantity) AS avg_order_quantity,
        MAX(ss.total_orders) AS max_orders_by_customer
    FROM 
        SalesSummary AS ss
    JOIN 
        customer_demographics AS cd ON ss.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd_gender,
    customer_count,
    total_net_profit,
    avg_order_quantity,
    max_orders_by_customer
FROM 
    DemographicsSummary
ORDER BY 
    total_net_profit DESC;
