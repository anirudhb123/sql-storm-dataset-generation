
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        ca_street_name,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS lower_city
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        LOWER(cd_gender) AS lower_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        CASE 
            WHEN ws_net_profit > 0 THEN 'Profitable' 
            ELSE 'Loss Making' 
        END AS profit_status
    FROM 
        web_sales
)
SELECT 
    ad.full_address,
    cd.full_name,
    SUM(sd.ws_quantity) AS total_quantity_sold,
    SUM(sd.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT cd.c_customer_id) AS unique_customers,
    ad.lower_city,
    cd.lower_gender,
    sd.profit_status
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON ad.ca_city = cd.lower_city
JOIN 
    SalesDetails sd ON sd.ws_order_number IN (SELECT DISTINCT ws_order_number FROM web_sales WHERE ws_item_sk IN 
        (SELECT DISTINCT ws_item_sk FROM store_sales WHERE ss_customer_sk = cd.c_customer_id))
GROUP BY 
    ad.full_address, cd.full_name, sd.profit_status, ad.lower_city, cd.lower_gender
HAVING 
    total_net_profit > 1000 AND unique_customers > 5
ORDER BY 
    total_net_profit DESC;
