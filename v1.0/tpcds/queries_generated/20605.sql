
WITH RECURSIVE income_stats AS (
    SELECT 
        ib_income_band_sk,
        NULLIF(ib_lower_bound, 0) AS lower_bound,
        NULLIF(ib_upper_bound, 0) AS upper_bound,
        1 AS depth
    FROM income_band
    WHERE ib_upper_bound IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ib.ib_income_band_sk,
        NULLIF(ib.ib_lower_bound, 0),
        NULLIF(ib.ib_upper_bound, 0),
        depth + 1
    FROM income_band ib
    JOIN income_stats is_prev ON 
        ib.ib_income_band_sk > is_prev.ib_income_band_sk
    WHERE depth < 5
),
customer_promise AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        (SELECT COUNT(DISTINCT sr.ticket_number) 
         FROM store_returns sr 
         WHERE sr.sr_customer_sk = c.c_customer_sk) AS returns_count,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL 
            THEN 'Not Estimated'
            WHEN cd.cd_purchase_estimate > 5000 
            THEN 'High Value'
            ELSE 'Regular Value' 
        END AS customer_value
    FROM customer c
    LEFT OUTER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_year > 1950
    AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
),
sales_department AS (
    SELECT 
        sd.s_store_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM store_sales ss
    JOIN store sd ON ss.ss_store_sk = sd.s_store_sk
    WHERE ss.ss_sold_date_sk = (
        SELECT MAX(d.d_date_sk) 
        FROM date_dim d 
        WHERE d.d_date = (SELECT MAX(d2.d_date) FROM date_dim d2)
    )
    GROUP BY sd.s_store_sk
),
waterfall_sales AS (
    SELECT 
        cs.cs_item_sk, 
        SUM(cs.cs_sales_price) AS catalog_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_sales_price) DESC) AS rnk
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    SUM(wp.wp_max_ad_count) AS total_ad_counts,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS unique_catalogs,
    SUM(CASE WHEN c.customer_value = 'High Value' THEN 1 ELSE 0 END) AS high_value_customers,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COALESCE(NULLIF(MAX(ss.ss_net_profit), 0), -1) AS max_profit,
    AVG(DISTINCT cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM customer_address ca
JOIN customer_promise c ON c.c_customer_sk = ca.ca_address_sk
LEFT JOIN sales_department sd ON sd.s_store_sk = ca.ca_address_sk
LEFT JOIN waterfall_sales w ON w.cs_item_sk IN (
    SELECT cs.cs_item_sk FROM catalog_sales cs 
    WHERE cs.cs_sales_price < 100 AND cs.cs_sales_price > 10
) 
LEFT JOIN web_page wp ON wp.wp_web_page_sk = c.c_customer_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE ca.ca_city NOT IN ('Atlantis', 'Narnia')
GROUP BY ca.ca_city, ca.ca_state, ca.ca_country
HAVING SUM(wp.wp_max_ad_count) > 50
ORDER BY total_ad_counts DESC, ca.ca_city;
