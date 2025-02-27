
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
top_websites AS (
    SELECT 
        web_site_sk,
        web_name
    FROM 
        ranked_sales
    WHERE 
        profit_rank <= 5
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS customer_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name
    FROM 
        customer_summary cs
    WHERE 
        cs.customer_net_profit > (
            SELECT AVG(customer_net_profit) FROM customer_summary
        )
)
SELECT 
    tw.web_name,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.customer_net_profit
FROM 
    top_websites tw
JOIN 
    web_sales ws ON tw.web_site_sk = ws.ws_web_site_sk
JOIN 
    high_value_customers hvc ON ws.ws_bill_customer_sk = hvc.c_customer_sk
ORDER BY 
    tw.web_name, hvc.customer_net_profit DESC;
