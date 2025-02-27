
WITH AddressBook AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                   THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        i.i_item_desc,
        i.i_current_price,
        cs.cs_net_profit
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
),
FullSalesReport AS (
    SELECT 
        cust.c_customer_id,
        cust.full_name,
        addr.full_address,
        addr.ca_city,
        addr.ca_state,
        addr.ca_zip,
        addr.ca_country,
        sales.cs_order_number,
        sales.cs_item_sk,
        sales.i_item_desc,
        sales.cs_quantity,
        sales.cs_net_profit
    FROM 
        CustomerInfo cust
    JOIN 
        AddressBook addr ON addr.ca_zip = '90210'  
    JOIN 
        SalesInfo sales ON cust.c_customer_id = (SELECT c_customer_id 
                                                  FROM customer c 
                                                  WHERE c.c_current_addr_sk = addr.ca_address_sk) 
)
SELECT 
    full_name,
    COUNT(DISTINCT cs_order_number) AS total_orders,
    SUM(cs_quantity) AS total_quantity,
    SUM(cs_net_profit) AS total_profit
FROM 
    FullSalesReport
GROUP BY 
    full_name 
ORDER BY 
    total_profit DESC
LIMIT 10;
