
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit, 
        ROW_NUMBER() OVER(PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
date_filter AS (
    SELECT 
        d.d_date_sk, 
        d.d_year
    FROM 
        date_dim d
    WHERE 
        d.d_year IN (2022, 2023)
)
SELECT 
    ca.ca_city, 
    ca.ca_state,
    cs.cd_gender,
    cs.cd_marital_status,
    SUM(ss.total_quantity) AS total_quantity_sold,
    AVG(cs.order_count) AS avg_orders_per_customer,
    COUNT(DISTINCT ss.web_site_id) FILTER (WHERE ss.total_profit > 0) AS profitable_websites
FROM 
    customer_address ca
JOIN 
    customer_summary cs ON ca.ca_address_sk = cs.c_customer_sk
JOIN 
    sales_summary ss ON cs.total_spent > 100
JOIN 
    date_filter df ON df.d_year = 2023
GROUP BY 
    ca.ca_city, ca.ca_state, cs.cd_gender, cs.cd_marital_status
ORDER BY 
    total_quantity_sold DESC, cs.cd_gender NULLS LAST;
