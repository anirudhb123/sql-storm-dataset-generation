
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_month,
        c_birth_year,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        Demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        CASE 
            WHEN ss.sold_date_sk IS NOT NULL THEN 'Store Sales'
            WHEN ws.sold_date_sk IS NOT NULL THEN 'Web Sales'
            ELSE 'Other Sales'
        END AS sales_type,
        c.full_name,
        SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) AS total_net_profit
    FROM 
        store_sales ss
    FULL OUTER JOIN 
        web_sales ws ON ss.ss_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        CustomerInfo c ON c.c_customer_sk = COALESCE(ss.ss_customer_sk, ws.ws_bill_customer_sk)
    GROUP BY 
        sales_type, c.full_name
),
FinalReport AS (
    SELECT 
        sales_type,
        full_name,
        total_net_profit,
        RANK() OVER (PARTITION BY sales_type ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        SalesSummary
)
SELECT 
    sales_type,
    full_name,
    total_net_profit,
    profit_rank
FROM 
    FinalReport
WHERE 
    profit_rank <= 10
ORDER BY 
    sales_type, profit_rank;
