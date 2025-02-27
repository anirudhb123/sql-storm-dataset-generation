
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT aa.ca_address_sk, aa.ca_city, aa.ca_state, aa.ca_country, level + 1
    FROM customer_address aa
    JOIN address_hierarchy ah ON aa.ca_state = ah.ca_state AND aa.ca_country = ah.ca_country
    WHERE aa.ca_city <> ah.ca_city AND ah.level < 3
),
customer_statistics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_store_sales,
        SUM(s.ss_net_paid) AS total_sales_amount,
        AVG(d.d_year) AS avg_year_of_purchase
    FROM customer c
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    LEFT JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE c.c_birth_year > 1980 OR c.c_birth_country IS NULL
    GROUP BY c.c_customer_sk
),
demographic_summary AS (
    SELECT 
        cd.cd_gender,
        SUM(cs.cs_quantity) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM customer_demographics cd
    LEFT JOIN catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    WHERE cd.cd_marital_status = 'M' OR cd.cd_credit_rating IS NULL
    GROUP BY cd.cd_gender
),
final_combined AS (
    SELECT 
        ah.ca_city,
        ah.ca_state,
        ah.ca_country,
        cs.total_store_sales,
        cs.total_sales_amount,
        dem.cd_gender,
        dem.total_catalog_sales,
        dem.total_catalog_orders,
        ROW_NUMBER() OVER (PARTITION BY ah.ca_country ORDER BY cs.total_sales_amount DESC) AS rank
    FROM address_hierarchy ah
    LEFT JOIN customer_statistics cs ON cs.c_customer_sk IN (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = ah.ca_address_sk)
    LEFT JOIN demographic_summary dem ON dem.cd_gender IS NOT NULL
)
SELECT 
    city,
    state,
    country,
    total_store_sales,
    total_sales_amount,
    cd_gender,
    total_catalog_sales,
    total_catalog_orders
FROM final_combined
WHERE rank <= 5
ORDER BY total_sales_amount DESC, city ASC NULLS LAST;
