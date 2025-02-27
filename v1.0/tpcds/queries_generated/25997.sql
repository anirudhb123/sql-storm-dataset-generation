
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), 
AddressDemographics AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesSummary AS (
    SELECT 
        ad.ca_city,
        ad.ca_state,
        SUM(cs.total_sales) AS city_sales,
        AVG(cs.total_sales) AS avg_sales_per_customer,
        COUNT(cs.c_customer_id) AS customer_count
    FROM 
        CustomerSales cs
    JOIN 
        AddressDemographics ad ON cs.c_customer_id = ad.ca_address_id
    GROUP BY 
        ad.ca_city, ad.ca_state
)
SELECT 
    city,
    state,
    city_sales,
    avg_sales_per_customer,
    customer_count
FROM 
    SalesSummary
WHERE 
    customer_count > 10
ORDER BY 
    city_sales DESC;
