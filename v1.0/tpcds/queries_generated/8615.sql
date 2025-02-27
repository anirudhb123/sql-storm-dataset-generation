
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        DATE(d.d_date) AS sales_date
    FROM 
        web_sales ws
    JOIN
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        ws.web_site_sk, DATE(d.d_date)
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.sales_date) AS active_dates,
        SUM(ss.total_quantity) AS total_quantity,
        SUM(ss.total_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.web_site_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses,
    AVG(ca_count) AS avg_customers_per_address,
    MAX(total_spent) AS max_spent,
    MIN(total_quantity) AS min_quantity
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_analysis a ON c.c_customer_sk = a.c_customer_sk
GROUP BY 
    ca.ca_city
ORDER BY 
    unique_addresses DESC, avg_customers_per_address DESC
LIMIT 10;
