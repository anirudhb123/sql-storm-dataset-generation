
WITH AddressWithDescription AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_country
    FROM 
        customer_address
),
CustomerWithDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(cd.cd_gender, ' - ', cd.cd_marital_status, ' - ', cd.cd_education_status) AS demographic_info
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        COALESCE(ss.total_sales, 0) AS total_sales
    FROM 
        CustomerWithDemographics c
    LEFT JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    t.customer_name,
    t.total_sales,
    a.full_address,
    a.ca_country
FROM 
    TopCustomers t
JOIN 
    customer_address a ON a.ca_address_sk = (
        SELECT ca_address_sk 
        FROM customer 
        WHERE c_customer_sk = t.c_customer_sk
    )
ORDER BY 
    t.total_sales DESC;
