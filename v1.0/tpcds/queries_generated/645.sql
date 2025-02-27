
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS customer_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > 1000
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM
        customer_demographics cd
)
SELECT 
    s.web_name,
    ss.total_net_profit,
    ss.total_orders,
    ss.unique_customers,
    COALESCE(hvc.customer_net_profit, 0) AS high_value_customer_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate
FROM 
    sales_summary ss
LEFT JOIN 
    high_value_customers hvc ON ss.unique_customers = hvc.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk IN (
        SELECT 
            c.c_current_cdemo_sk 
        FROM 
            customer c 
        WHERE 
            c.c_current_cdemo_sk IS NOT NULL
    )
ORDER BY 
    ss.total_net_profit DESC
LIMIT 10;
