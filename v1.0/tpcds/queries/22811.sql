
WITH RECURSIVE income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 1 AS level
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, b.level + 1
    FROM income_band ib
    JOIN income_brackets b ON ib.ib_income_band_sk = b.ib_income_band_sk
    WHERE b.level < 5
),
sales_summary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_street_number,
        ca.ca_city,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
ranked_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.ca_city,
        ci.gender,
        ib.ib_income_band_sk,
        RANK() OVER (PARTITION BY ci.ca_city ORDER BY COUNT(DISTINCT ci.c_customer_sk) DESC) AS city_rank
    FROM customer_info ci
    LEFT JOIN income_brackets ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ci.c_customer_sk, ci.ca_city, ci.gender, ib.ib_income_band_sk
)
SELECT 
    r.c_customer_sk,
    r.ca_city,
    r.gender,
    r.ib_income_band_sk,
    ss.total_quantity,
    ss.total_profit,
    ss.profit_rank
FROM ranked_customers r
LEFT JOIN sales_summary ss ON r.c_customer_sk = ss.cs_item_sk
WHERE 
    (r.ib_income_band_sk IS NOT NULL OR r.ib_income_band_sk IS NULL)
    AND r.city_rank = 1
ORDER BY r.ca_city, total_profit DESC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM ranked_customers) / 2;
