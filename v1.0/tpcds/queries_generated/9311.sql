
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        MIN(ws.ws_sold_date_sk) AS first_sale_date,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate > 100
        AND ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws.web_site_id
),
address_summary AS (
    SELECT 
        ca.city,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_dep_college_count) AS avg_college_deps
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state = 'NY'
    GROUP BY 
        ca.city
)
SELECT 
    ss.web_site_id,
    ss.total_sales,
    ss.total_orders,
    ss.avg_net_profit,
    ss.first_sale_date,
    ss.last_sale_date,
    asu.city,
    asu.total_customers,
    asu.avg_college_deps
FROM 
    sales_summary ss
LEFT JOIN 
    address_summary asu ON ss.total_orders > 100
ORDER BY 
    ss.total_sales DESC, 
    asu.total_customers DESC;
