
WITH SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        ws.web_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS total_unique_customers
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        w.web_open_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_dow = 5) 
        AND d_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        ws.web_site_sk, w.web_id
)
SELECT 
    ss.web_site_sk,
    ss.web_id,
    ss.total_net_profit,
    ss.total_orders,
    ss.average_order_value,
    ss.total_unique_customers,
    wd.d_month_seq AS month,
    wd.d_year AS year
FROM 
    SalesSummary ss
JOIN 
    date_dim wd ON wd.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
ORDER BY 
    ss.total_net_profit DESC
LIMIT 10;
