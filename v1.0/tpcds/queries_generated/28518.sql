
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' ', ca_suite_number), ''), ', ', 
               ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_country,
        ca_location_type
    FROM 
        customer_address
), 
CustomerDetails AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
ReturnReasons AS (
    SELECT 
        r.r_reason_id,
        r.r_reason_desc,
        COUNT(sr_return_quantity) AS return_count
    FROM 
        store_returns sr
    JOIN 
        reason r ON sr_reason_sk = r.r_reason_sk
    GROUP BY 
        r.r_reason_id, r.r_reason_desc
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ad.full_address,
    ad.ca_country,
    COALESCE(rd.return_count, 0) AS total_returns,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_quantity, 0) AS total_quantity
FROM 
    CustomerDetails cd
LEFT JOIN 
    AddressDetails ad ON cd.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_current_addr_sk = ad.ca_address_sk)
LEFT JOIN 
    ReturnReasons rd ON cd.c_customer_id = rd.r_reason_id
LEFT JOIN 
    SalesData sd ON cd.c_customer_id = sd.ws_bill_customer_sk
ORDER BY 
    total_sales DESC, total_returns DESC
LIMIT 100;
