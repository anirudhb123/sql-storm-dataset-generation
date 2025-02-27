
WITH RECURSIVE income_bracket AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT b.ib_income_band_sk, b.ib_lower_bound, b.ib_upper_bound
    FROM income_bracket a
    JOIN income_band b ON a.ib_upper_bound = b.ib_lower_bound
),
address_usage AS (
    SELECT ca_address_id, COUNT(DISTINCT c_customer_sk) AS customer_count, 
           AVG(c_birth_year) AS avg_birth_year
    FROM customer_address AS ca
    JOIN customer AS c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca_address_id
),
sales_summary AS (
    SELECT ws_sold_date_sk, ws_item_sk, 
           SUM(ws_quantity) AS total_sold,
           SUM(ws_net_profit) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
returns_summary AS (
    SELECT cr_item_sk, 
           SUM(cr_return_quantity) AS total_returns,
           SUM(cr_return_amount) AS total_return_value
    FROM catalog_returns
    GROUP BY cr_item_sk
),
final AS (
    SELECT 
        a.ca_address_id,
        COALESCE(s.total_sold, 0) AS total_sold,
        COALESCE(s.total_profit, 0) AS total_profit,
        r.total_returns,
        r.total_return_value,
        demo.cd_marital_status,
        demo.cd_gender,
        demo.cd_education_status,
        i.ib_income_band_sk
    FROM address_usage a
    LEFT JOIN sales_summary s ON a.customer_count > 1000
    LEFT JOIN returns_summary r ON s.ws_item_sk = r.cr_item_sk
    LEFT JOIN customer_demographics demo ON a.customer_count >= 1 
    LEFT JOIN income_bracket i ON demo.cd_purchase_estimate BETWEEN i.ib_lower_bound AND i.ib_upper_bound
)
SELECT 
    fa.ca_address_id,
    fa.total_sold,
    fa.total_profit,
    fa.total_returns,
    fa.total_return_value,
    COUNT(CASE WHEN fa.cd_gender = 'F' THEN 1 END) AS female_count,
    COUNT(CASE WHEN fa.cd_gender = 'M' THEN 1 END) AS male_count,
    MAX(CASE WHEN fa.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS has_married,
    CONCAT('A ', fa.ca_address_id, ' has a profit margin of ', 
           ROUND((fa.total_profit / NULLIF((fa.total_sold + fa.total_returns), 0)) * 100, 2), '%') AS profit_margin
FROM final fa
GROUP BY fa.ca_address_id, fa.total_sold, fa.total_profit, fa.total_returns, fa.total_return_value
ORDER BY fa.total_profit DESC 
LIMIT 10
OFFSET 5;
