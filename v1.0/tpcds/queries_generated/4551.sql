
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    COALESCE(SUM(ss.total_quantity), 0) AS total_web_sales_quantity,
    COALESCE(SUM(ss.total_revenue), 0) AS total_web_sales_revenue,
    AVG(CASE WHEN ca.ca_state IS NOT NULL THEN ca.ca_gmt_offset ELSE NULL END) AS avg_gmt_offset,
    COUNT(DISTINCT CASE WHEN ca.ca_country IS NULL THEN c.c_customer_sk END) AS undefined_country_customers
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_summary ss ON ss.ws_sold_date_sk = c.c_first_sales_date_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    total_web_sales_revenue DESC
LIMIT 10;
