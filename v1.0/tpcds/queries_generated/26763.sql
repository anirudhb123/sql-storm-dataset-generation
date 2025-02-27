
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS addr_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND
        ca_state IS NOT NULL 
),
FilteredDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status 
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'F' OR
        (cd_marital_status = 'M' AND cd_education_status LIKE '%College%')
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
TopSalesCustomers AS (
    SELECT 
        ws_bill_customer_sk,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
    WHERE 
        total_sales > 1000
)
SELECT 
    ca.ca_address_sk,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    tsc.total_sales,
    tsc.order_count
FROM 
    RankedAddresses ca
JOIN 
    FilteredDemographics cd ON ca.addr_rank = 1
JOIN 
    TopSalesCustomers tsc ON ca.ca_address_sk = tsc.ws_bill_customer_sk
WHERE 
    ca.ca_zip LIKE '9%' 
ORDER BY 
    ca.ca_city ASC, 
    tsc.total_sales DESC;
