
WITH sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MIN(ws.ws_sold_date_sk) AS first_purchase_date,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales ws
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate > 50000
    GROUP BY 
        ws.ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cs.total_sales,
        cs.total_orders,
        cs.avg_sales_price,
        cs.first_purchase_date,
        cs.last_purchase_date
    FROM 
        sales_summary cs
    JOIN 
        customer c ON cs.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    city,
    state,
    country,
    COUNT(DISTINCT ws_bill_customer_sk) AS customer_count,
    SUM(total_sales) AS city_total_sales,
    AVG(avg_sales_price) AS avg_city_sales_price,
    MIN(first_purchase_date) AS earliest_purchase,
    MAX(last_purchase_date) AS latest_purchase
FROM 
    customer_details
GROUP BY 
    ca_city, ca_state, ca_country
ORDER BY 
    city_total_sales DESC
LIMIT 10;
