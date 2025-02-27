
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_zip,
        COUNT(*) OVER (PARTITION BY ca_city) AS city_count
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        (LOWER(ca_state) = 'ca' OR LOWER(ca_state) = 'ny')
),
FilteredDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
    WHERE 
        cd_marital_status IN ('M', 'S') AND 
        cd_gender = 'F'
),
SalesInfo AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS sales_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20211231
    GROUP BY 
        ws_item_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    d.cd_gender,
    d.cd_marital_status,
    s.total_sales,
    s.sales_count,
    RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
FROM 
    RankedAddresses a
JOIN 
    FilteredDemographics d ON a.ca_address_sk = d.cd_demo_sk
JOIN 
    SalesInfo s ON s.ws_item_sk IN (
        SELECT ws_item_sk 
        FROM web_sales 
        WHERE ws_bill_customer_sk IN (
            SELECT c_customer_sk 
            FROM customer 
            WHERE c_current_addr_sk = a.ca_address_sk
        )
    )
WHERE 
    a.city_count > 10
ORDER BY 
    sales_rank;
