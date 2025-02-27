
WITH RECURSIVE sales_performance AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2020
    GROUP BY 
        ws.web_site_sk
    HAVING 
        total_net_profit > 50000
),
customer_return_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk 
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        cr.c_customer_sk,
        cr.total_returns,
        cr.total_return_amount,
        cd.cd_marital_status,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY cr.total_return_amount DESC) AS rank_by_marital_status
    FROM 
        customer_return_stats cr
    JOIN 
        customer_demographics cd ON cr.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    sp.web_site_sk,
    sp.total_net_profit,
    tc.c_customer_sk,
    tc.total_returns,
    tc.total_return_amount,
    tc.cd_marital_status,
    tc.cd_gender
FROM 
    sales_performance sp
JOIN 
    top_customers tc ON sp.web_site_sk = (SELECT ws.web_site_sk FROM web_sales ws WHERE ws.ws_order_number IN 
        (SELECT DISTINCT ws_order_number FROM web_sales WHERE ws_net_profit > 1000))
WHERE 
    tc.rank_by_marital_status <= 5
ORDER BY 
    sp.total_net_profit DESC, 
    tc.total_return_amount DESC;
