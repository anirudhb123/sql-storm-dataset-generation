
WITH AddressSummary AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS all_address_details
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
GenderStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        d_year,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    JOIN 
        date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY 
        d_year
),
CustomerInsights AS (
    SELECT 
        c_first_name,
        c_last_name,
        ca_city,
        cd_gender,
        cd_marital_status,
        COALESCE(cd_purchase_estimate, 0) AS purchase_estimate
    FROM 
        customer
    LEFT JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    LEFT JOIN 
        customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
)
SELECT 
    AddressSummary.ca_city,
    AddressSummary.unique_addresses,
    AddressSummary.all_address_details,
    GenderStats.customer_count AS total_customers,
    GenderStats.avg_purchase_estimate,
    SalesSummary.total_quantity,
    SalesSummary.total_sales,
    CustomerInsights.c_first_name,
    CustomerInsights.c_last_name,
    CustomerInsights.purchase_estimate
FROM 
    AddressSummary
JOIN 
    GenderStats ON 1=1
JOIN 
    SalesSummary ON 1=1
JOIN 
    CustomerInsights ON AddressSummary.ca_city = CustomerInsights.ca_city
ORDER BY 
    AddressSummary.ca_city, CustomerInsights.purchase_estimate DESC;
