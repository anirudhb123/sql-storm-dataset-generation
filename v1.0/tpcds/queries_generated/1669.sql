
WITH sales_summary AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id
),
customer_details AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        cust.c_customer_id,
        cust.cd_gender,
        cust.cd_marital_status,
        cust.cd_purchase_estimate,
        sales.total_sales,
        sales.order_count
    FROM 
        customer_details cust
    JOIN 
        sales_summary sales ON cust.c_customer_id = sales.web_site_id
    WHERE 
        cust.customer_rank = 1 AND sales.total_sales > 1000
)
SELECT 
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COUNT(DISTINCT hvc.c_customer_id) AS high_value_customer_count,
    SUM(hvc.total_sales) AS total_sales,
    AVG(hvc.order_count) AS avg_orders_per_customer
FROM 
    high_value_customers hvc
LEFT JOIN 
    customer_address ca ON hvc.c_customer_id = ca.ca_address_id
GROUP BY 
    ca.ca_city
ORDER BY 
    total_sales DESC
FETCH FIRST 10 ROWS ONLY;
