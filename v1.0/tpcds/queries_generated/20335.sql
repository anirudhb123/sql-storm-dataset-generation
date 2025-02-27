
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        (SELECT COUNT(*) 
         FROM customer c 
         WHERE c.c_current_addr_sk = ca.ca_address_sk 
         AND c.c_birth_year BETWEEN 1980 AND 2000) AS customer_count
    FROM customer_address ca
    WHERE ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
),
PromotionsData AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(cs.cs_order_number) AS promo_order_count,
        SUM(cs.cs_net_profit) AS total_profit
    FROM promotion p
    LEFT JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    WHERE p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY p.p_promo_id, p.p_promo_name
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    COALESCE(SUM(r.ws_net_profit), 0) AS total_profit_from_sales,
    COALESCE(MAX(p.total_profit), 0) AS max_promo_profit,
    CASE 
        WHEN COUNT(DISTINCT c.c_customer_id) > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS customer_status
FROM CustomerAddresses ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN RankedSales r ON r.ws_web_site_sk = (SELECT web_site_sk FROM web_site WHERE web_site_id = 'site_01') 
                           AND r.ws_item_sk IN (SELECT DISTINCT cs_item_sk FROM catalog_sales WHERE cs_quantity > 0)
LEFT JOIN PromotionsData p ON p.p_promo_id IN (SELECT DISTINCT wp_autogen_flag FROM web_page WHERE wp_web_page_sk = (SELECT MAX(wp_web_page_sk) FROM web_page))
WHERE ca.customer_count > 0
GROUP BY ca.ca_city, ca.ca_state, ca.ca_country
HAVING SUM(r.ws_net_profit) IS NOT NULL 
ORDINARY JOIN 
    (SELECT ws_item_sk, AVG(ws_net_profit) OVER (PARTITION BY ws_item_sk) AS avg_profit 
     FROM web_sales 
     WHERE ws_net_profit IS NOT NULL) AS averaged_profit ON r.ws_item_sk = averaged_profit.ws_item_sk
ORDER BY total_profit_from_sales DESC, unique_customers DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM customer) / 2;
