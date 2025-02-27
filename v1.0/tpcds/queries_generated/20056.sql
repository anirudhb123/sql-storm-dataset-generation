
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c_current_cdemo_sk,
        1 AS hierarchy_level
    FROM customer c
    WHERE c.c_birth_year < 1980
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c_current_cdemo_sk,
        ch.hierarchy_level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE c.c_birth_year IS NOT NULL
),
max_income AS (
    SELECT 
        cd.cd_demo_sk,
        MAX(ib.ib_upper_bound) AS max_band
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY cd.cd_demo_sk
),
customer_info AS (
    SELECT 
        ch.c_customer_id,
        ch.c_first_name,
        ch.c_last_name,
        ch.hierarchy_level,
        mi.max_band,
        CASE 
            WHEN ch.hierarchy_level = 1 THEN 'New Customer'
            WHEN ch.hierarchy_level > 5 THEN 'Senior Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM customer_hierarchy ch
    LEFT JOIN max_income mi ON ch.c_current_cdemo_sk = mi.cd_demo_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_current_cdemo_sk,
    COALESCE(si.store_count, 0) AS store_count,
    COALESCE(wi.web_count, 0) AS web_count,
    ci.max_band,
    ci.customer_type
FROM customer c
LEFT JOIN (
    SELECT 
        ss_customer_sk,
        COUNT(DISTINCT ss_store_sk) AS store_count
    FROM store_sales
    GROUP BY ss_customer_sk
) si ON c.c_customer_sk = si.ss_customer_sk
LEFT JOIN (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_web_site_sk) AS web_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
) wi ON c.c_customer_sk = wi.ws_bill_customer_sk
JOIN customer_info ci ON c.c_current_cdemo_sk = ci.c_current_cdemo_sk
WHERE c.c_preferred_cust_flag = 'Y'
AND ci.max_band > (
    SELECT AVG(ib.ib_upper_bound) FROM income_band ib
)
ORDER BY ci.hierarchy_level DESC, ci.max_band DESC;
