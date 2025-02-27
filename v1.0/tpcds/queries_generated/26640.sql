
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.web_site_id,
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        ws.web_site_id, w.w_warehouse_id
)
SELECT 
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sd.total_sales) AS total_sales,
    COUNT(sd.order_count) AS unique_order_count
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    SalesData sd ON sd.web_site_id IN (SELECT web_site_id FROM web_site) -- Filter condition
GROUP BY 
    ad.full_address, cd.full_name, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales DESC
LIMIT 100;
