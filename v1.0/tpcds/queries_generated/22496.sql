
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_current_cdemo_sk, 
        0 AS depth 
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        ch.c_customer_sk, 
        ch.c_first_name, 
        ch.c_last_name, 
        ch.c_current_cdemo_sk, 
        depth + 1 
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
)

, demographic_data AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(*) AS customer_count,
        COUNT(DISTINCT ch.c_customer_sk) AS unique_customers,
        SUM(cd.cd_purchase_estimate) AS total_estimated_purchase
    FROM customer_hierarchy ch
    JOIN customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)

SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.customer_count,
    d.unique_customers,
    d.total_estimated_purchase,
    RANK() OVER (PARTITION BY d.cd_gender ORDER BY d.total_estimated_purchase DESC) AS rank,
    CASE 
        WHEN d.total_estimated_purchase IS NULL THEN 'Unknown Total'
        ELSE CASE 
            WHEN d.total_estimated_purchase > 100000 THEN 'High Spender'
            WHEN d.total_estimated_purchase > 50000 THEN 'Medium Spender'
            ELSE 'Low Spender'
        END
    END AS spending_category
FROM demographic_data d
LEFT JOIN (
    SELECT 
        ca.ca_country, 
        COUNT(DISTINCT ca.ca_address_sk) AS country_count
    FROM customer_address ca
    GROUP BY ca.ca_country
) country_data ON d.cd_gender IN (SELECT CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END FROM customer_demographics)
WHERE d.customer_count > 10
ORDER BY d.cd_gender, d.total_estimated_purchase DESC
LIMIT 5;

SELECT 
    DISTINCT ws.web_site_id, 
    ws.web_name
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) 
                          FROM web_sales ws2 
                          WHERE ws2.ws_item_sk = ws.ws_item_sk)
AND 
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_item_sk = ws.ws_item_sk) > 5
EXCEPT
SELECT 
    DISTINCT wr.web_site_id, 
    wr.web_name
FROM web_returns wr  
WHERE wr.wr_return_amt < (SELECT AVG(wr2.wr_return_amt)
                           FROM web_returns wr2
                           WHERE wr2.wr_item_sk = wr.wr_item_sk);
