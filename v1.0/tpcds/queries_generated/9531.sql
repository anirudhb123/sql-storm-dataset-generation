
WITH RankedPurchases AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        customer_id, 
        c_first_name, 
        c_last_name, 
        total_spent 
    FROM 
        RankedPurchases 
    WHERE 
        rank <= 10
)
SELECT 
    h.customer_id,
    h.c_first_name,
    h.c_last_name,
    h.total_spent,
    ca.ca_city,
    ca.ca_state,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status
FROM 
    HighSpenders h
JOIN 
    customer_demographics c ON h.customer_id = c.cd_demo_sk
JOIN 
    customer_address ca ON c.cd_demo_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA'
ORDER BY 
    h.total_spent DESC;
