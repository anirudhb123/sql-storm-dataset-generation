
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        SUM(s.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT s.ws_order_number) AS total_orders,
        AVG(s.ws_net_profit) AS avg_profit
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS s ON c.c_customer_sk = s.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_gender
),
DemographicStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        SUM(cs.total_sales) AS total_sales,
        AVG(cs.total_orders) AS avg_orders,
        AVG(cs.avg_profit) AS avg_profit
    FROM 
        CustomerStats AS cs
    JOIN 
        customer_demographics AS cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
DateStats AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales_by_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders_by_year
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ds.d_year,
    ds.total_sales_by_year,
    ds.total_orders_by_year,
    ds.total_sales_by_year / NULLIF(ds.total_orders_by_year, 0) AS avg_order_value,
    dem.cd_gender,
    dem.customer_count,
    dem.total_sales,
    dem.avg_orders,
    dem.avg_profit
FROM 
    DateStats AS ds
JOIN 
    DemographicStats AS dem ON ds.total_sales_by_year > 1000000
ORDER BY 
    ds.d_year DESC, dem.customer_count DESC;
