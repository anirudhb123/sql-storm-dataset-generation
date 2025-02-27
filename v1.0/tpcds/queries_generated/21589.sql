
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 0 AS level
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state, ca_country, level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_state = ah.ca_state AND ca.ca_country = ah.ca_country
    WHERE ah.level < 2
),
income_stats AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(hd.hd_dep_count) AS total_dependents
    FROM household_demographics hd
    JOIN customer c ON hd.hd_demo_sk = c.c_current_cdemo_sk
    GROUP BY hd.hd_income_band_sk
),
sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    GROUP BY ws.web_site_id
),
returns_summary AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(cr.cr_order_number) AS total_returns
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
    GROUP BY cr.returning_customer_sk
)
SELECT 
    ah.ca_city,
    ah.ca_state,
    ah.ca_country,
    is.hd_income_band_sk,
    is.customer_count AS total_customers,
    is.total_dependents,
    ss.web_site_id,
    ss.total_net_profit,
    ss.avg_sales_price,
    rs.total_return_amount,
    rs.total_returns,
    CASE 
        WHEN rs.total_return_amount IS NULL THEN 'No Returns'
        WHEN rs.total_return_amount > 1000 THEN 'High Returns'
        ELSE 'Normal Returns'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY ah.ca_city ORDER BY ah.ca_country DESC) AS rank_city_country,
    RANK() OVER (ORDER BY ss.total_net_profit DESC) AS rank_net_profit 
FROM address_hierarchy ah
JOIN income_stats is ON ah.ca_country = COALESCE(is.hd_income_band_sk::text, '')
LEFT JOIN sales_summary ss ON ss.web_site_id = 'web_id_placeholder'
FULL OUTER JOIN returns_summary rs ON rs.returning_customer_sk = (VALUES(NULL)) 
WHERE ah.level < 2
ORDER BY ah.ca_city, is.customer_count DESC, ss.total_net_profit DESC 
FETCH FIRST 100 ROWS ONLY;
