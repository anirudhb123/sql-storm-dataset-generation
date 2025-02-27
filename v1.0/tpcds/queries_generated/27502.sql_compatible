
WITH AddressDetails AS (
    SELECT 
        CA.ca_address_id,
        CONCAT(CA.ca_street_number, ' ', CA.ca_street_name, ' ', CA.ca_street_type, 
               CASE WHEN CA.ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', CA.ca_suite_number) ELSE '' END) AS formatted_address,
        CA.ca_city,
        CA.ca_state,
        CA.ca_zip,
        CA.ca_country
    FROM 
        customer_address CA
),
DemographicDetails AS (
    SELECT 
        CD.cd_demo_sk,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_education_status,
        CASE 
            WHEN CD.cd_purchase_estimate BETWEEN 0 AND 500 THEN 'Low'
            WHEN CD.cd_purchase_estimate BETWEEN 501 AND 2000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_band
    FROM 
        customer_demographics CD
),
SalesData AS (
    SELECT 
        WS.ws_order_number,
        WS.ws_quantity,
        WS.ws_sales_price,
        WS.ws_net_paid,
        WS.ws_ship_date_sk,
        AA.formatted_address,
        DD.cd_gender,
        DD.purchase_estimate_band
    FROM 
        web_sales WS
    JOIN 
        AddressDetails AA ON WS.ws_ship_addr_sk = AA.ca_address_id
    JOIN 
        DemographicDetails DD ON WS.ws_bill_cdemo_sk = DD.cd_demo_sk
    WHERE 
        WS.ws_ship_date_sk BETWEEN 20220101 AND 20220331
)
SELECT 
    sd.purchase_estimate_band,
    COUNT(sd.ws_order_number) AS total_orders,
    SUM(sd.ws_quantity) AS total_quantity,
    SUM(sd.ws_net_paid) AS total_revenue,
    AVG(sd.ws_sales_price) AS average_sales_price
FROM 
    SalesData sd
GROUP BY 
    sd.purchase_estimate_band
ORDER BY 
    total_revenue DESC;
