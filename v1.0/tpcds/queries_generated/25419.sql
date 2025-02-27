
WITH AddressInfo AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT('Suite: ', ca_suite_number) ELSE 'No Suite' END AS suite_info
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        a.full_address,
        a.suite_info
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        AddressInfo a ON c.c_current_addr_sk = a.ca_address_id
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ci.c_first_name,
        ci.c_last_name,
        COUNT(ws.ws_item_sk) AS total_items,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
    GROUP BY 
        ws.ws_order_number, ci.c_first_name, ci.c_last_name
)
SELECT 
    si.ws_order_number,
    si.c_first_name,
    si.c_last_name,
    si.total_items,
    si.total_sales,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value' 
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS value_category
FROM 
    SalesInfo si
WHERE 
    si.total_items > 5
ORDER BY 
    si.total_sales DESC;
