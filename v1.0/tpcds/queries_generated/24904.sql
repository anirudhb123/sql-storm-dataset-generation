
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, 
           ca_city, 
           ca_state, 
           ca_country, 
           ca_street_name, 
           1 AS level
    FROM customer_address 
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, 
           a.ca_city, 
           a.ca_state, 
           a.ca_country, 
           a.ca_street_name, 
           ah.level + 1
    FROM customer_address a
    JOIN address_hierarchy ah ON a.ca_state = ah.ca_state AND a.ca_country = ah.ca_country
    WHERE a.ca_city IS NOT NULL AND ah.level < 5
), 
sales_summary AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
), 
demographic_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(ss.total_sales) AS total_revenue,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_purchase_estimate < 1000 THEN 'LOW'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'MEDIUM'
            ELSE 'HIGH'
        END AS purchase_band
    FROM customer_demographics cd
    LEFT JOIN sales_summary ss ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, purchase_band
),
item_analysis AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        AVG(ws.ws_net_profit) AS average_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id, i.i_product_name
) 
SELECT 
    ah.ca_city, 
    ah.ca_state, 
    d.cd_gender, 
    d.cd_marital_status, 
    d.purchase_band, 
    COALESCE(i.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(i.average_profit, 0) AS average_profit,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM address_hierarchy ah
LEFT JOIN demographic_analysis d ON ah.ca_state = d.cd_marital_status
LEFT JOIN item_analysis i ON d.purchase_band = (
    CASE 
        WHEN i.average_profit > 5000 THEN 'HIGH'
        WHEN i.average_profit BETWEEN 1000 AND 5000 THEN 'MEDIUM'
        ELSE 'LOW' 
    END
) 
LEFT JOIN customer c ON c.c_current_addr_sk = ah.ca_address_sk
WHERE ah.level > 1
GROUP BY ah.ca_city, ah.ca_state, d.cd_gender, d.cd_marital_status, d.purchase_band, i.total_quantity_sold, i.average_profit
ORDER BY ah.ca_city ASC, d.cd_gender DESC, unique_customers DESC;

