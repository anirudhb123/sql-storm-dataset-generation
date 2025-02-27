
WITH address_counts AS (
    SELECT 
        ca_city,
        COUNT(*) AS num_addresses,
        COUNT(DISTINCT ca_address_id) AS unique_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        address_counts.num_addresses,
        address_counts.unique_addresses
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        address_counts ON ca.ca_city = address_counts.ca_city
), 
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.num_addresses,
    ci.unique_addresses,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders
FROM 
    customer_info AS ci
LEFT JOIN 
    sales_summary AS ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    ci.total_sales DESC, 
    ci.c_last_name ASC, 
    ci.c_first_name ASC
LIMIT 100;
