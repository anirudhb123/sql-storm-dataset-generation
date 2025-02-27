
WITH address_summary AS (
    SELECT 
        ca.city AS city,
        ca.state AS state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_revenue
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        ca.city, ca.state
),
demographics_summary AS (
    SELECT 
        cd.cd_gender AS gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender
),
sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)

SELECT 
    a.city, 
    a.state, 
    a.customer_count AS address_customer_count,
    a.total_sales AS address_total_sales,
    a.total_revenue AS address_total_revenue,
    d.gender, 
    d.customer_count AS demographic_customer_count,
    d.average_purchase_estimate,
    s.sales_year,
    s.total_quantity,
    s.total_net_paid
FROM 
    address_summary a
JOIN 
    demographics_summary d ON a.customer_count > 0
JOIN 
    sales_summary s ON s.total_quantity > 0
ORDER BY 
    a.total_revenue DESC, 
    d.average_purchase_estimate DESC, 
    s.total_net_paid DESC;
