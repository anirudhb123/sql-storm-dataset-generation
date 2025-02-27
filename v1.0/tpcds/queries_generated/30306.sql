
WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i_item_sk, 
        i_item_id, 
        i_item_desc, 
        i_current_price, 
        1 AS level
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        CONCAT(ih.i_item_desc, ' > ', i.i_item_desc) AS i_item_desc, 
        i.i_current_price,
        ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON i.i_item_sk = ih.i_item_sk -- Hypothetical parent-child relationship
    WHERE ih.level < 5 -- Limiting the depth of hierarchy
), 
sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws.ws_item_sk
),
combined_data AS (
    SELECT 
        ih.i_item_id,
        ih.i_item_desc,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_revenue, 0) AS total_revenue,
        ih.level
    FROM item_hierarchy ih
    LEFT JOIN sales_data sd ON ih.i_item_sk = sd.ws_item_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ca.ca_city AS customer_city,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
    AVG(ct.total_revenue) AS average_revenue_per_item,
    COUNT(DISTINCT ib.ib_income_band_sk) AS distinct_income_bands
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN combined_data ct ON ct.i_item_id IN (
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    WHERE cs.cs_order_number IN (SELECT ss_ticket_number FROM store_sales WHERE ss_customer_sk = c.c_customer_sk)
)
LEFT JOIN income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE cd.cd_credit_rating IS NOT NULL
GROUP BY customer_name, ca.ca_city, cd.cd_gender, cd.cd_marital_status
HAVING SUM(cd.cd_purchase_estimate) > 10000
ORDER BY average_revenue_per_item DESC
LIMIT 10;
