
WITH CustomerAddress AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
SalesStats AS (
    SELECT 
        ws_bill_addr_sk AS address_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
),
RankedSales AS (
    SELECT 
        s.address_sk,
        s.total_sales,
        s.order_count,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SalesStats s
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    rs.total_sales,
    rs.order_count,
    rs.sales_rank
FROM 
    CustomerAddress ca
JOIN 
    RankedSales rs ON ca.ca_address_sk = rs.address_sk
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
ORDER BY 
    rs.total_sales DESC, ca.ca_city, cd.cd_gender;
