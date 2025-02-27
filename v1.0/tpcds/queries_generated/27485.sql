
WITH processed_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        TRIM(UPPER(c.c_email_address)) AS normalized_email,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        c.c_email_address IS NOT NULL
        AND c.c_email_address <> ''
),
address_summary AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca.city, ca.ca_state) AS full_address,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state
)
SELECT
    pc.full_name,
    pc.normalized_email,
    pc.cd_gender,
    pc.hd_buy_potential,
    asum.full_address,
    asum.customer_count,
    ROW_NUMBER() OVER (PARTITION BY pc.cd_income_band_sk ORDER BY pc.purchase_count DESC) AS rank_by_purchases
FROM 
    processed_customers pc
JOIN 
    address_summary asum ON pc.c_customer_sk = (SELECT MIN(c.c_customer_sk) FROM customer c WHERE c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_address_sk = pc.c_current_addr_sk))
ORDER BY 
    pc.cd_income_band_sk, rank_by_purchases
LIMIT 100;
