
WITH RECURSIVE AddressHierarchy AS (
    SELECT 
        ca_address_sk, 
        ca_address_id, 
        ca_city, 
        ca_state,
        ca_country,
        1 as level
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT 
        a.ca_address_sk, 
        a.ca_address_id, 
        a.ca_city, 
        a.ca_state,
        a.ca_country,
        h.level + 1
    FROM customer_address a
    JOIN AddressHierarchy h ON a.ca_city = h.ca_city AND a.ca_state = h.ca_state AND a.ca_country != h.ca_country
)

SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ca.ca_address_id) AS unique_addresses,
    AVG(DATE_PART('year', AGE(NOW(), d.d_date))) AS avg_customer_age,
    SUM(ws.ws_net_profit) AS total_net_profit,
    MAX(CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Unknown' 
    END) AS gender_description,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS product_names
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    AddressHierarchy ah ON ah.ca_address_id = ca.ca_address_id
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    d.d_year = 2023 
    AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
GROUP BY 
    c.c_customer_id
HAVING 
    SUM(ws.ws_net_profit) > 
    (SELECT 
        AVG(ws2.ws_net_profit)
     FROM 
        web_sales ws2
     WHERE 
        ws2.ws_ship_date_sk <= (SELECT MAX(d2.d_date_sk) FROM date_dim d2 WHERE d2.d_year = 2022))
ORDER BY 
    unique_addresses DESC,
    avg_customer_age DESC
LIMIT 100 OFFSET 10;
