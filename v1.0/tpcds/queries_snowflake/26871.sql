
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS UniqueAddresses,
        LISTAGG(DISTINCT ca_street_name, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS StreetNames,
        LISTAGG(DISTINCT ca_street_type, ', ') WITHIN GROUP (ORDER BY ca_street_type) AS StreetTypes
    FROM customer_address
    GROUP BY ca_city, ca_state
),
DemographicDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) AS TotalPurchaseEstimate,
        COUNT(cd_demo_sk) AS CustomerCount
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
RevenueByDemographics AS (
    SELECT 
        d.d_year,
        dd.cd_gender,
        dd.cd_marital_status,
        SUM(ws.ws_net_paid) AS TotalRevenue
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics dd ON c.c_current_cdemo_sk = dd.cd_demo_sk
    GROUP BY d.d_year, dd.cd_gender, dd.cd_marital_status
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.UniqueAddresses,
    ad.StreetNames,
    ad.StreetTypes,
    dd.cd_gender,
    dd.cd_marital_status,
    dd.TotalPurchaseEstimate,
    dd.CustomerCount,
    rbd.TotalRevenue
FROM AddressDetails ad
JOIN DemographicDetails dd ON 1=1
LEFT JOIN RevenueByDemographics rbd ON dd.cd_gender = rbd.cd_gender AND dd.cd_marital_status = rbd.cd_marital_status
ORDER BY ad.ca_city, ad.ca_state, dd.cd_gender, dd.cd_marital_status;
