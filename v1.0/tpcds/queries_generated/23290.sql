
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_country, ca_state, ca_city, ca_county,
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM customer_address
    WHERE ca_country IS NOT NULL
),
customer_stats AS (
    SELECT c.c_customer_sk, 
           MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
           SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
           SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
           COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
promotions AS (
    SELECT p.p_promo_name, 
           COUNT(DISTINCT ws.ws_order_number) AS total_sales
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_name
),
outer_promotions AS (
    SELECT COALESCE(pm.p_promo_name, 'No Promotion') AS promo_name,
           pm.total_sales,
           (SELECT COUNT(*) FROM store_sales) AS total_store_sales
    FROM promotions pm
    FULL OUTER JOIN (
        SELECT DISTINCT p.p_promo_name
        FROM promotion p
    ) all_promos ON pm.p_promo_name = all_promos.p_promo_name
),
final_summary AS (
    SELECT ah.ca_state, 
           COUNT(DISTINCT cs.c_customer_sk) AS total_customers,
           SUM(op.total_sales) AS total_promo_sales,
           SUM(cs.max_purchase_estimate) AS aggregate_purchase_estimate
    FROM address_hierarchy ah
    LEFT JOIN customer_stats cs ON ah.city_rank = 1 AND cs.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = ah.ca_address_sk)
    LEFT JOIN outer_promotions op ON 1=1
    GROUP BY ah.ca_state
    ORDER BY total_customers DESC
)

SELECT DISTINCT fs.ca_state,
       fs.total_customers,
       COALESCE(fs.total_promo_sales / NULLIF(fs.total_customers, 0), 0) AS avg_sales_per_customer,
       ROUND(fs.aggregate_purchase_estimate / NULLIF(fs.total_customers, 0), 2) AS avg_purchase_estimate,
       CASE 
           WHEN fs.total_customers IS NULL THEN 'No Data'
           WHEN fs.total_customers = 0 THEN 'No Customers'
           ELSE 'Active Customers'
       END AS customer_status
FROM final_summary fs
WHERE fs.aggregate_purchase_estimate IS NOT NULL
ORDER BY fs.total_customers DESC
LIMIT 10;
