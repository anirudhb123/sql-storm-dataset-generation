
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length,
        UPPER(ca_city) AS upper_city
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA'
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'F' AND 
        cd_purchase_estimate > 5000
),
SalesSummary AS (
    SELECT 
        s_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS sales_count
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
),
FinalReport AS (
    SELECT 
        pa.ca_address_sk,
        pa.full_address,
        cd.cd_demo_sk,
        cd.cd_gender,
        ss.total_sales,
        ss.sales_count,
        pa.upper_city
    FROM 
        ProcessedAddresses pa
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = (SELECT TOP 1 cd_demo_sk FROM customer WHERE c_current_addr_sk = pa.ca_address_sk)
    LEFT JOIN 
        SalesSummary ss ON ss.s_store_sk = (SELECT TOP 1 s_store_sk FROM store WHERE s_street_name = pa.ca_street_name)
)
SELECT 
    full_address,
    upper_city,
    COUNT(DISTINCT cd_demo_sk) AS demographic_count,
    SUM(total_sales) AS total_revenue,
    AVG(sales_count) AS average_sales
FROM 
    FinalReport
GROUP BY 
    full_address, upper_city
ORDER BY 
    total_revenue DESC;
