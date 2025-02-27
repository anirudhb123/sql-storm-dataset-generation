
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_city, ca.ca_state
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesAnalysis AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        SUM(d.total_profit) AS total_profit_by_address
    FROM 
        AddressDetails ad
    JOIN 
        Demographics d ON ad.total_customers > 0
    GROUP BY 
        ad.full_address, ad.ca_city, ad.ca_state, d.cd_gender, d.cd_marital_status, d.cd_education_status
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_profit_by_address DESC) AS rank
    FROM 
        SalesAnalysis
)

SELECT 
    full_address,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_profit_by_address,
    rank
FROM 
    RankedSales
WHERE 
    rank <= 5
ORDER BY 
    ca_state, rank;
