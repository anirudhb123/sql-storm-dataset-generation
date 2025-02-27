
WITH address_summary AS (
    SELECT 
        ca_country, 
        ca_state, 
        COUNT(DISTINCT ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities
    FROM 
        customer_address
    GROUP BY 
        ca_country, ca_state
),
customer_summary AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        WS.web_site_id, 
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discounts,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales WS
    JOIN 
        web_site W ON WS.ws_web_site_sk = W.web_site_sk
    GROUP BY 
        WS.web_site_id
)
SELECT 
    a.ca_country,
    a.ca_state,
    a.address_count,
    a.cities,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    s.web_site_id,
    s.total_sales,
    s.total_discounts,
    s.total_orders
FROM 
    address_summary a
JOIN 
    customer_summary c ON c.customer_count > 0
JOIN 
    sales_summary s ON s.total_sales > 0
ORDER BY 
    a.ca_country, a.ca_state, c.customer_count DESC, s.total_sales DESC;
