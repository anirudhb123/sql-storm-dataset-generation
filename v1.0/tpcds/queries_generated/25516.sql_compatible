
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS lower_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_revenue
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
)
SELECT 
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    sd.total_quantity,
    sd.total_revenue
FROM 
    AddressData ad
JOIN 
    CustomerData cd ON cd.c_customer_sk IN (
        SELECT DISTINCT sr_customer_sk 
        FROM store_returns 
        WHERE sr_store_sk IN (
            SELECT s_store_sk 
            FROM store 
            WHERE s_city = ad.lower_city AND s_state = ad.ca_state
        )
    )
JOIN 
    SalesData sd ON sd.ss_item_sk IN (
        SELECT sr_item_sk 
        FROM store_returns 
        WHERE sr_customer_sk = cd.c_customer_sk
    )
WHERE 
    ad.ca_zip LIKE '12345%' 
    AND cd.cd_marital_status = 'M'
GROUP BY 
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    sd.total_quantity,
    sd.total_revenue
ORDER BY 
    sd.total_revenue DESC
LIMIT 100;
