
WITH AddressDetails AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_type, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city
),
CustomerDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        STRING_AGG(c.first_name || ' ' || c.last_name, ', ') AS customer_names
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate
),
SalesDetails AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
)
SELECT 
    a.ca_state,
    a.ca_city,
    a.address_count,
    a.street_names,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.cd_purchase_estimate,
    c.customer_names,
    s.total_sales,
    s.order_count
FROM 
    AddressDetails a
JOIN 
    CustomerDetails c ON a.ca_city IN (SELECT DISTINCT ca_city FROM customer_address WHERE ca_state = a.ca_state)
LEFT JOIN 
    SalesDetails s ON s.ws_item_sk IN (SELECT DISTINCT i_item_sk FROM item WHERE i_manufact_id IN (SELECT DISTINCT cd_demo_sk FROM customer_demographics WHERE cd_gender = c.cd_gender)) 
ORDER BY 
    a.ca_state, a.ca_city, c.cd_purchase_estimate DESC;
