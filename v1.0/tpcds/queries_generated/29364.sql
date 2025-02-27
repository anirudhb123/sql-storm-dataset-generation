
WITH CustomerAddressInfo AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('CA', 'NY', 'TX')
),
DemographicInfo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_credit_rating IN ('Good', 'Fair')
),
PurchaseHistory AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
)

SELECT 
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    di.cd_gender,
    di.cd_marital_status,
    di.cd_purchase_estimate,
    ph.total_quantity,
    ph.total_sales
FROM 
    CustomerAddressInfo ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    DemographicInfo di ON di.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    PurchaseHistory ph ON ph.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    di.cd_purchase_estimate > 1000
ORDER BY 
    ph.total_sales DESC
LIMIT 100;
