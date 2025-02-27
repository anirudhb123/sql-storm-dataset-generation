
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        MAX(ws_sales_price) AS max_price, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
address_counts AS (
    SELECT 
        ca_address_sk,
        COUNT(c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_address_sk
),
income_band_summary AS (
    SELECT 
        ib_income_band_sk,
        SUM(hd_dep_count) AS total_dependents,
        COUNT(DISTINCT hd_demo_sk) AS total_households
    FROM household_demographics
    LEFT JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    GROUP BY ib_income_band_sk
)
SELECT 
    ca.ca_city,
    COALESCE(ac.customer_count, 0) AS customer_count,
    r.total_quantity,
    r.max_price,
    ib.total_dependents,
    ib.total_households
FROM customer_address ca
LEFT JOIN address_counts ac ON ca.ca_address_sk = ac.ca_address_sk
LEFT JOIN ranked_sales r ON r.ws_item_sk = (
    SELECT ws_item_sk FROM web_sales
    WHERE ws_ship_customer_sk = (
        SELECT c_customer_sk 
        FROM customer 
        WHERE c_current_addr_sk = ca.ca_address_sk
        LIMIT 1
    ) 
    ORDER BY ws_sales_price DESC 
    LIMIT 1
)
LEFT JOIN income_band_summary ib ON ib.ib_income_band_sk = (
    SELECT DISTINCT hd_income_band_sk 
    FROM household_demographics 
    WHERE hd_demo_sk IN (
        SELECT DISTINCT c_current_hdemo_sk 
        FROM customer 
        WHERE c_current_addr_sk = ca.ca_address_sk
    )
    LIMIT 1
)
WHERE 
    ca.ca_state = 'NY' 
    AND EXISTS (
        SELECT 1 
        FROM web_sales 
        WHERE ws_item_sk = r.ws_item_sk 
        AND ws_quantity > (
            SELECT AVG(ws_quantity) 
            FROM web_sales 
            WHERE ws_ship_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31' LIMIT 1) 
            AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31' LIMIT 1)
        )
    )
ORDER BY customer_count DESC
LIMIT 50;
