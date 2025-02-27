
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
PopularCities AS (
    SELECT 
        ca.ca_city,
        COUNT(*) AS total_customers
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_city
),
CustomerSummary AS (
    SELECT 
        rc.c_customer_sk,
        CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS full_name,
        rc.cd_gender,
        pc.ca_city,
        rc.purchase_rank
    FROM RankedCustomers rc
    JOIN PopularCities pc ON rc.c_customer_sk IN (
        SELECT c.c_customer_sk 
        FROM customer c 
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE ca.ca_city = pc.ca_city
    )
    WHERE rc.purchase_rank <= 10
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.ca_city,
    GROUP_CONCAT(DISTINCT cs.purchase_rank ORDER BY cs.purchase_rank) AS ranked_purchases
FROM CustomerSummary cs
GROUP BY 
    cs.full_name, 
    cs.cd_gender,
    cs.ca_city
ORDER BY 
    cs.ca_city, 
    COUNT(cs.purchase_rank) DESC;
