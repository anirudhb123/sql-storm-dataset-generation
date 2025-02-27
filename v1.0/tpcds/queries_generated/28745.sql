
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_country LIKE 'United States'
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesInfo AS (
    SELECT 
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        ws.ws_bill_cdemo_sk
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_cdemo_sk
),
CombinedData AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cu.customer_count,
        si.total_sales_quantity,
        si.total_sales_amount
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        SalesInfo si ON cd.cd_demo_sk = si.ws_bill_cdemo_sk
    LEFT JOIN 
        (SELECT COUNT(*) AS customer_count, cd_demo_sk FROM customer GROUP BY cd_demo_sk) cu ON cd.cd_demo_sk = cu.cd_demo_sk
)
SELECT 
    gender,
    marital_status,
    education_status,
    customer_count,
    total_sales_quantity,
    total_sales_amount,
    AVG(total_sales_amount) OVER (PARTITION BY gender) AS avg_sales_per_gender,
    INITCAP(full_address) as formatted_address
FROM 
    CombinedData
JOIN 
    AddressDetails ad ON ad.ca_city = 'Los Angeles' AND ad.ca_state = 'CA'
ORDER BY 
    customer_count DESC
LIMIT 100;
