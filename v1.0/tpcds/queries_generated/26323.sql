
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        UPPER(ca_street_name) AS street_name_upper,
        SUBSTRING(ca_street_type, 1, 3) AS street_type_abbr,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender_desc
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
EnhancedSales AS (
    SELECT 
        ws.ws_order_number,
        cs.cs_order_number AS catalog_order_number,
        ss.ss_order_number AS store_order_number,
        COALESCE(ws.ws_sales_price, cs.cs_sales_price, ss.ss_sales_price) AS sale_price,
        COALESCE(ws.ws_net_profit, cs.cs_net_profit, ss.ss_net_profit) AS net_profit,
        CASE 
            WHEN ws.ws_order_number IS NOT NULL THEN 'Web Sale'
            WHEN cs.cs_order_number IS NOT NULL THEN 'Catalog Sale'
            WHEN ss.ss_order_number IS NOT NULL THEN 'Store Sale'
            ELSE NULL
        END AS sale_channel
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_order_number
)
SELECT 
    cd.full_name,
    cd.gender_desc,
    ad.full_address,
    es.sale_channel,
    SUM(es.net_profit) AS total_net_profit,
    COUNT(es.sale_channel) AS sale_count
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    EnhancedSales es ON cd.c_customer_sk = es.ws_sold_date_sk
WHERE 
    es.sale_channel IS NOT NULL
GROUP BY 
    cd.full_name, 
    cd.gender_desc, 
    ad.full_address,
    es.sale_channel
ORDER BY 
    total_net_profit DESC;
