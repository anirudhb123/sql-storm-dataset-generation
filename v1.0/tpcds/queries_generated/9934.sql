
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating, 
        cd.cd_dep_count, 
        cd.cd_dep_employed_count, 
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_web_page_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_id
    GROUP BY 
        ws.ws_web_page_sk
),
AggregateSales AS (
    SELECT 
        s.ws_web_page_sk,
        AVG(total_net_profit) AS avg_net_profit,
        AVG(total_quantity) AS avg_quantity,
        COUNT(DISTINCT order_count) AS unique_orders
    FROM 
        SalesData s
    GROUP BY 
        s.ws_web_page_sk
)
SELECT 
    a.ws_web_page_sk,
    a.avg_net_profit,
    a.avg_quantity,
    a.unique_orders,
    wp.wp_creation_date_sk
FROM 
    AggregateSales a
JOIN 
    web_page wp ON a.ws_web_page_sk = wp.wp_web_page_sk
WHERE 
    wp.wp_creation_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
ORDER BY 
    a.avg_net_profit DESC
LIMIT 10;
