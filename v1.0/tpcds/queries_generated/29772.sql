
WITH AddressData AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city
),
CustomerData AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) AS total_purchases,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk, 
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
CombinedData AS (
    SELECT 
        a.ca_state,
        a.ca_city,
        a.address_count,
        a.full_address_list,
        c.cd_gender,
        c.cd_marital_status,
        c.total_purchases,
        c.customer_count,
        COALESCE(s.total_sales, 0) AS total_sales
    FROM 
        AddressData a
    JOIN 
        CustomerData c ON a.ca_city = c.cd_gender
    LEFT JOIN 
        SalesData s ON c.cd_demo_sk = s.ws_bill_cdemo_sk
)
SELECT 
    ca_state,
    ca_city,
    address_count,
    full_address_list,
    cd_gender,
    cd_marital_status,
    total_purchases,
    customer_count,
    total_sales
FROM 
    CombinedData
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
