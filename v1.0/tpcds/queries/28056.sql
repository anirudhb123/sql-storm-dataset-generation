
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        ca_country,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM 
        customer_address
    JOIN 
        customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
    JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        ca_city, ca_state, ca_country
),
SalesSummary AS (
    SELECT 
        ca_city,
        ca_state,
        ca_country,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    JOIN 
        customer_address ON web_sales.ws_ship_addr_sk = customer_address.ca_address_sk
    GROUP BY 
        ca_city, ca_state, ca_country
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    ad.customer_count,
    ad.street_names,
    ad.male_count,
    ad.female_count,
    ss.total_net_profit,
    ss.total_quantity_sold
FROM 
    AddressDetails ad
LEFT JOIN 
    SalesSummary ss ON ad.ca_city = ss.ca_city AND ad.ca_state = ss.ca_state AND ad.ca_country = ss.ca_country
ORDER BY 
    ad.customer_count DESC, 
    ss.total_net_profit DESC
LIMIT 10;
