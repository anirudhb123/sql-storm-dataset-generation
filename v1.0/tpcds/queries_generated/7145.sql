
WITH sales_summary AS (
    SELECT 
        d.d_year,
        c.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        d.d_year, c.cd_gender
),
top_sales AS (
    SELECT 
        d.d_year,
        cd_gender,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS rank
    FROM 
        sales_summary
)
SELECT 
    s.d_year,
    s.cd_gender,
    s.total_quantity,
    s.total_sales,
    s.avg_net_profit
FROM 
    sales_summary s
JOIN 
    top_sales t ON s.d_year = t.d_year AND s.cd_gender = t.cd_gender
WHERE 
    t.rank <= 3
ORDER BY 
    s.d_year, s.total_sales DESC;
