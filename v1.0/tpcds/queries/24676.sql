
WITH AddressCounts AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count
    FROM 
        customer_address 
    GROUP BY 
        ca_state
),
CustomerPurchaseStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_birth_country,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_birth_country
    HAVING 
        SUM(COALESCE(ws.ws_quantity, 0)) > 0
),
HighSpenderDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT cps.c_customer_sk) AS high_spender_count,
        AVG(cps.total_spent) AS avg_spent
    FROM 
        customer_demographics cd
    JOIN 
        CustomerPurchaseStats cps ON cd.cd_demo_sk = cps.c_customer_sk 
    WHERE 
        cps.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchaseStats)
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    ac.ca_state,
    hsd.cd_gender,
    hsd.cd_marital_status,
    hsd.cd_education_status,
    COALESCE(hsd.high_spender_count, 0) AS high_spender_count,
    ac.address_count
FROM 
    AddressCounts ac
LEFT JOIN 
    HighSpenderDemographics hsd ON ac.ca_state = (SELECT MIN(dc.ca_state) FROM customer_address dc WHERE dc.ca_state IS NOT NULL GROUP BY dc.ca_state ORDER BY hsd.high_spender_count DESC LIMIT 1)
ORDER BY 
    ac.address_count DESC, 
    hsd.high_spender_count DESC;
