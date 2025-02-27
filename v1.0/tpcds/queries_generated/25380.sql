
WITH AddressComponents AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
DemographicInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemographicInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.full_name,
    cd.full_address,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(sd.avg_order_value, 0) AS avg_order_value
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.ca_city LIKE 'San%' AND
    cd.cd_purchase_estimate > 1000
ORDER BY 
    cd.total_net_profit DESC, cd.full_name ASC;
