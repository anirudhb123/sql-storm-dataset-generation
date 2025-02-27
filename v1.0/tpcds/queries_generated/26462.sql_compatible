
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

AddressWithStateCount AS (
    SELECT 
        ca.ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_state
),

RecentSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_bill_customer_sk
)

SELECT 
    rc.c_customer_id,
    CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    awsc.address_count,
    COALESCE(rs.total_profit, 0) AS total_profit
FROM 
    RankedCustomers rc
LEFT JOIN 
    AddressWithStateCount awsc ON rc.c_customer_sk = awsc.ca_state
LEFT JOIN 
    RecentSales rs ON rc.c_customer_sk = rs.ws_bill_customer_sk
WHERE 
    rc.rank <= 5
ORDER BY 
    rc.cd_gender, rc.c_birth_year DESC;
