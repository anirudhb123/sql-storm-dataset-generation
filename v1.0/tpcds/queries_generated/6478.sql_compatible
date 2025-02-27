
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
        AND c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        ws.web_site_id, d.d_year
),
average_sales AS (
    SELECT 
        web_site_id,
        d_year,
        AVG(total_quantity) AS avg_quantity,
        AVG(total_net_profit) AS avg_net_profit,
        AVG(total_orders) AS avg_orders
    FROM 
        sales_summary
    GROUP BY 
        web_site_id, d_year
),
top_web_sites AS (
    SELECT 
        web_site_id,
        d_year,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY avg_net_profit DESC) AS rank
    FROM 
        average_sales
)
SELECT 
    w.web_site_id,
    w.web_name,
    avg_sales.avg_quantity,
    avg_sales.avg_net_profit,
    avg_sales.avg_orders,
    ts.rank
FROM 
    top_web_sites ts
JOIN 
    average_sales avg_sales ON ts.web_site_id = avg_sales.web_site_id AND ts.d_year = avg_sales.d_year
JOIN 
    web_site w ON ts.web_site_id = w.web_site_id
WHERE 
    ts.rank <= 5
ORDER BY 
    ts.d_year, ts.rank;
