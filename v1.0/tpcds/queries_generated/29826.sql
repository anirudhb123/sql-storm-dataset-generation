
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_street_number, ca_street_name, ca_city, ca_state, ca_zip
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesStats AS (
    SELECT
        case 
            when ws_sales_price < 100 then 'Low'
            when ws_sales_price BETWEEN 100 AND 500 then 'Medium'
            when ws_sales_price > 500 then 'High'
        end as price_band,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_ext_sales_price) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        price_band
)
SELECT 
    ad.full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    ss.price_band,
    SUM(ss.total_sales_quantity) AS sales_quantity,
    SUM(ss.total_sales_amount) AS sales_revenue
FROM 
    AddressDetails ad
JOIN 
    customer c ON c.c_current_addr_sk = (SELECT ca_address_sk FROM customer_address WHERE CONCAT(ca_street_number, ' ', ca_street_name) = ad.full_address LIMIT 1)
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    SalesStats ss ON TRUE
GROUP BY 
    ad.full_address, cd.cd_gender, cd.cd_marital_status, ss.price_band
ORDER BY 
    ad.full_address, cd.cd_gender;
