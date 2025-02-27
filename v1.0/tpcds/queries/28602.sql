
WITH Address_Summary AS (
    SELECT 
        ca_state, 
        ca_city, 
        COUNT(DISTINCT ca_address_id) AS unique_address_count,
        MAX(ca_gmt_offset) AS max_gmt_offset,
        MIN(ca_gmt_offset) AS min_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city
),
Sales_Summary AS (
    SELECT 
        ws_ship_mode_sk, 
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_tax) AS total_tax
    FROM 
        web_sales
    GROUP BY 
        ws_ship_mode_sk
),
Customer_Gender AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
String_Processing AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_customer_name,
        SUBSTR(c_email_address, 1, 8) AS email_prefix,
        UPPER(c_customer_id) AS upper_customer_id,
        ca_city || ', ' || ca_state AS full_address
    FROM 
        customer
    JOIN 
        customer_address ON c_current_addr_sk = ca_address_sk
)
SELECT 
    addr.ca_state,
    addr.ca_city,
    sales.total_orders,
    sales.total_sales,
    sales.total_tax,
    gender.cd_gender,
    gender.customer_count,
    STRING_AGG(proc.full_customer_name, ', ') AS full_customer_names,
    STRING_AGG(proc.email_prefix, ', ') AS email_prefixes,
    STRING_AGG(proc.upper_customer_id, ', ') AS upper_customer_ids,
    STRING_AGG(proc.full_address, ', ') AS full_addresses
FROM 
    Address_Summary addr
JOIN 
    Sales_Summary sales ON addr.unique_address_count > 50
JOIN 
    Customer_Gender gender ON TRUE
JOIN 
    String_Processing proc ON TRUE
GROUP BY 
    addr.ca_state, addr.ca_city, sales.total_orders, sales.total_sales, sales.total_tax, gender.cd_gender, gender.customer_count
ORDER BY 
    addr.ca_state, addr.ca_city;
