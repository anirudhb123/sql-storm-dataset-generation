
WITH AddressAndDemographics AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating, 
        cd.cd_dep_count,
        CONCAT(cd.cd_gender, '-', cd.cd_marital_status) AS gender_marital,
        CASE 
            WHEN cd.cd_purchase_estimate < 50000 THEN 'Low' 
            WHEN cd.cd_purchase_estimate BETWEEN 50000 AND 150000 THEN 'Medium' 
            ELSE 'High' 
        END AS purchase_estimate_category
    FROM 
        customer_address ca
    JOIN 
        customer_demographics cd ON ca.ca_address_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state = 'CA'
        AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status = 'S')
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) as total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        AddressAndDemographics ad ON ws.ws_bill_customer_sk = ad.ca_address_id
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.gender_marital,
    ad.purchase_estimate_category,
    sd.total_sales,
    sd.order_count
FROM 
    AddressAndDemographics ad
JOIN 
    SalesData sd ON ad.ca_address_id = sd.ws_bill_customer_sk
ORDER BY 
    ad.ca_city, 
    sd.total_sales DESC;
