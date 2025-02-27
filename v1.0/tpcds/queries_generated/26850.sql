
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        cs.cs_ext_sales_price AS catalog_sales_price,
        ss.ss_ext_sales_price AS store_sales_price,
        COALESCE(ws.ws_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0) AS total_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    LEFT JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
)
SELECT 
    cd.full_name,
    cd.gender,
    cd.marital_status,
    SUM(sd.total_sales) AS total_spent,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders,
    MAX(sd.total_sales) AS max_order_value
FROM 
    CustomerDetails cd
JOIN 
    SalesData sd ON cd.c_customer_id = sd.ws_order_number
GROUP BY 
    cd.full_name, cd.gender, cd.marital_status
ORDER BY 
    total_spent DESC
LIMIT 100;
