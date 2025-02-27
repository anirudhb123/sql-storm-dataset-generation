
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country
    FROM customer_address a
    JOIN address_cte cte ON a.ca_city = cte.ca_city AND a.ca_country = cte.ca_country
    WHERE a.ca_address_sk <> cte.ca_address_sk
), demographic_summary AS (
    SELECT cd_gender, 
           COUNT(DISTINCT c.c_customer_id) AS customer_count, 
           AVG(cd_purchase_estimate) AS avg_purchase_estimate,
           SUM(CASE 
                   WHEN cd_marital_status = 'M' THEN 1 
                   ELSE 0 
               END) AS married_count,
           SUM(CASE 
                   WHEN cd_gender = 'F' THEN 1 
                   ELSE 0 
               END) AS female_count
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd_gender
), return_summary AS (
    SELECT 
        sr_reason_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        COALESCE(MAX(sr_return_quantity), 0) AS max_return_quantity,
        COALESCE(AVG(sr_return_quantity), 0) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_reason_sk
), web_return_summary AS (
    SELECT 
        wr_reason_sk,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_value,
        COALESCE(MAX(wr_return_quantity), 0) AS max_web_return_quantity,
        COALESCE(AVG(wr_return_quantity), 0) AS avg_web_return_quantity
    FROM web_returns
    GROUP BY wr_reason_sk
), combined_returns AS (
    SELECT 
        COALESCE(sr.sr_reason_sk, wr.wr_reason_sk) AS reason_sk,
        SUM(COALESCE(sr.total_returns, 0) + COALESCE(wr.total_web_returns, 0)) AS combined_total_returns,
        SUM(COALESCE(sr.total_return_value, 0) + COALESCE(wr.total_web_return_value, 0)) AS combined_total_return_value
    FROM return_summary sr
    FULL OUTER JOIN web_return_summary wr ON sr.sr_reason_sk = wr.wr_reason_sk
    GROUP BY COALESCE(sr.sr_reason_sk, wr.wr_reason_sk)
)
SELECT 
    a.cte_city AS city,
    a.cte_state AS state,
    a.cte_country AS country,
    d.cd_gender,
    d.customer_count,
    d.avg_purchase_estimate,
    d.married_count,
    d.female_count,
    r.reason_sk,
    r.combined_total_returns,
    r.combined_total_return_value
FROM 
    (SELECT DISTINCT ca_city AS cte_city, ca_state AS cte_state, ca_country AS cte_country 
     FROM address_cte) AS a
LEFT JOIN demographic_summary d ON a.cte_city LIKE '%' || d.cd_gender || '%'
LEFT JOIN combined_returns r ON r.reason_sk IS NOT NULL
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_item_sk IN (
        SELECT cs.cs_item_sk
        FROM catalog_sales cs
        WHERE cs.cs_order_number IN (
            SELECT ws.ws_order_number
            FROM web_sales ws
            WHERE ws.ws_ship_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales)
        )
    )
)
ORDER BY a.cte_country, d.cd_gender DESC, r.combined_total_returns DESC
LIMIT 100;
