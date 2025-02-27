
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
SalesSummary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid) AS average_net_paid,
        COUNT(*) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    asum.address_count,
    asum.unique_cities,
    ss.total_profit,
    ss.average_net_paid,
    ss.total_orders
FROM 
    RankedCustomers rc
LEFT JOIN 
    SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_cdemo_sk
LEFT JOIN 
    AddressSummary asum ON rc.c_customer_sk = asum.ca_address_sk
WHERE 
    rc.gender_rank <= 10
ORDER BY 
    rc.cd_gender, rc.c_last_name;
