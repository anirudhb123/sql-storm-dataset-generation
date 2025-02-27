
WITH RECURSIVE address_ranks AS (
    SELECT ca_address_sk, 
           ca_city, 
           ca_state, 
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk DESC) AS city_rank
    FROM customer_address
), 
 demographic_analysis AS (
    SELECT cd_demo_sk, 
           cd_gender, 
           COUNT(*) OVER (PARTITION BY cd_gender) AS gender_count,
           AVG(cd_purchase_estimate) OVER (PARTITION BY cd_gender) AS average_estimate
    FROM customer_demographics
), 
 sales_per_category AS (
    SELECT cs.cs_item_sk, 
           SUM(cs.cs_quantity) AS total_quantity,
           SUM(cs.cs_net_paid) AS total_net_paid,
           MAX(cs.cs_sales_price) AS max_sales_price
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
), 
 top_products AS (
    SELECT i.i_item_sk, 
           i.i_product_name, 
           sp.total_quantity,
           RANK() OVER (ORDER BY sp.total_net_paid DESC) AS product_rank
    FROM sales_per_category sp
    JOIN item i ON sp.cs_item_sk = i.i_item_sk
    WHERE sp.total_quantity > 0
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    addr.ca_city,
    addr.ca_state,
    dem.cd_gender,
    dem.average_estimate,
    tp.i_product_name,
    tp.product_rank,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    COUNT(DISTINCT web.wp_web_page_sk) AS distinct_web_visits,
    CASE 
        WHEN addr.city_rank = 1 THEN 'Top Address'
        ELSE 'Regular Address' 
    END AS address_status
FROM customer cu
LEFT JOIN customer_demographics dem ON cu.c_current_cdemo_sk = dem.cd_demo_sk
LEFT JOIN customer_address addr ON cu.c_current_addr_sk = addr.ca_address_sk
LEFT JOIN web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN top_products tp ON ws.ws_item_sk = tp.i_item_sk AND tp.product_rank <= 10
LEFT JOIN store_returns sr ON cu.c_customer_sk = sr.sr_customer_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE dem.cd_marital_status = 'M' 
AND addr.ca_state IS NOT NULL
GROUP BY cu.c_first_name, 
         cu.c_last_name, 
         addr.ca_city, 
         addr.ca_state, 
         dem.cd_gender, 
         dem.average_estimate,
         tp.i_product_name,
         tp.product_rank,
         addr.city_rank
ORDER BY total_returns DESC, dem.average_estimate DESC
LIMIT 50;
