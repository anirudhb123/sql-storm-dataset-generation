
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.sold_date_sk = dd.d_date_sk
    JOIN 
        customer AS c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2022 AND 
        cd.cd_marital_status = 'M' AND 
        cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_sk
),
top_sites AS (
    SELECT 
        web_site_id,
        total_profit
    FROM 
        ranked_sales AS rs
    JOIN 
        web_site AS w ON rs.web_site_sk = w.web_site_sk
    WHERE 
        profit_rank <= 5
)
SELECT 
    w.web_site_id,
    w.web_name,
    ts.total_profit,
    COUNT(DISTINCT ws.order_number) AS total_orders,
    AVG(ws.net_paid_inc_tax) AS average_order_value
FROM 
    top_sites AS ts
JOIN 
    web_site AS w ON ts.web_site_id = w.web_site_id
JOIN 
    web_sales AS ws ON w.web_site_sk = ws.web_site_sk
GROUP BY 
    w.web_site_id, w.web_name, ts.total_profit
ORDER BY 
    ts.total_profit DESC;
