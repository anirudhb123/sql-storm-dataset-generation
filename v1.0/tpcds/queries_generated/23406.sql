
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sales_price > 20.00
    GROUP BY ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS average_net_profit,
        MAX(COALESCE(ws_net_paid_inc_tax, 0)) AS max_net_paid
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd.cd_dep_count IS NULL THEN 1 ELSE 0 END) AS null_dependents
    FROM customer_demographics cd
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    AVG(cs.average_net_profit) AS average_customer_profit,
    MIN(CASE WHEN r.r_reason_desc IS NOT NULL THEN r.r_reason_desc END) AS non_null_reason,
    SUM(COALESCE(ss.ss_quantity, 0)) AS total_store_sales,
    STRING_AGG(DISTINCT wp.wp_url, ', ') AS web_page_urls
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN inventory i ON c.c_curr_addr_sk = i.inv_item_sk
LEFT JOIN catalog_sales cs ON i.inv_item_sk = cs.cs_item_sk
LEFT JOIN web_page wp ON cs.cs_order_number = wp.wp_web_page_sk
LEFT JOIN reason r ON cs.cs_promo_sk = r.r_reason_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE ca.ca_state IN ('NY', 'CA')
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY unique_customers DESC
LIMIT 10;
