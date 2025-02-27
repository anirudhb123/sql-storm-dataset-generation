
WITH address_count AS (
    SELECT ca_state, COUNT(*) AS address_total
    FROM customer_address
    GROUP BY ca_state
),
customer_count AS (
    SELECT c_birth_country, COUNT(*) AS customer_total
    FROM customer
    GROUP BY c_birth_country
),
combined AS (
    SELECT 
        ac.ca_state,
        cc.c_birth_country,
        ac.address_total,
        cc.customer_total,
        COALESCE(cc.customer_total, 0) AS customer_total,
        COALESCE(ac.address_total, 0) AS address_total,
        CASE 
            WHEN COALESCE(cc.customer_total, 0) = 0 THEN 0
            ELSE ROUND(COALESCE(cc.customer_total, 0) * 100.0 / ac.address_total, 2)
        END AS customer_to_address_ratio
    FROM address_count ac
    FULL OUTER JOIN customer_count cc ON ac.ca_state = cc.c_birth_country
)
SELECT
    ca_state,
    c_birth_country,
    address_total,
    customer_total,
    customer_to_address_ratio
FROM combined
WHERE (customer_to_address_ratio > 50 OR (customer_total = 0 AND address_total > 0))
ORDER BY ca_state, c_birth_country;
