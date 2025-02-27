
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_number,
        ca.ca_street_name,
        ca.ca_street_type,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_id
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cd.full_name,
        cd.full_address
    FROM 
        web_sales ws
    JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_id
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
)
SELECT
    sd.full_name,
    sd.full_address,
    COUNT(sd.ws_order_number) AS total_orders,
    SUM(sd.cs_sales_price) AS total_sales,
    SUM(sd.cs_net_profit) AS total_profit
FROM 
    SalesData sd
GROUP BY 
    sd.full_name, sd.full_address
ORDER BY 
    total_sales DESC
LIMIT 10;
