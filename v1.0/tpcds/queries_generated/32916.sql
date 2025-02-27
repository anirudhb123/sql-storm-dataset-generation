
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_totals AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_store_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count,
        AVG(ss.ss_list_price) AS average_list_price
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    s.web_site_sk,
    s.total_net_profit,
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    sa.total_store_net_profit,
    sa.total_sales_count
FROM 
    sales_data s
LEFT JOIN 
    customer_summary cs ON cs.rank <= 10
JOIN 
    sales_totals sa ON sa.total_store_net_profit > 1000 
WHERE 
    s.rn = 1
ORDER BY 
    s.total_net_profit DESC, sa.total_store_net_profit DESC;
