
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
popular_items AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_moy = 12
    )
    GROUP BY ws.ws_item_sk
    HAVING total_quantity > 100
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(NULLIF(i.i_brand, ''), 'Unknown') AS calculated_brand
    FROM item i
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    pi.total_quantity,
    id.i_item_desc,
    id.i_current_price,
    ci.rank,
    (CASE 
        WHEN ci.cd_gender = 'F' AND ci.cd_marital_status = 'M' THEN 'Married Female'
        WHEN ci.cd_gender = 'M' AND ci.cd_marital_status = 'S' THEN 'Single Male'
        ELSE 'Other'
     END) AS demographic_group,
    (SELECT AVG(total_quantity) FROM popular_items) AS avg_quantity,
    (SELECT COUNT(DISTINCT c.c_customer_sk) 
     FROM customer c 
     WHERE c.c_current_cdemo_sk IS NOT NULL) AS total_customers,
    COALESCE(SUM(ws.ws_net_profit) FILTER (WHERE ws.ws_sold_date_sk IS NOT NULL), 0) AS total_net_profit
FROM customer_info ci
JOIN popular_items pi ON ci.c_customer_sk = pi.ws_item_sk
JOIN item_details id ON pi.ws_item_sk = id.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = id.i_item_sk AND ws.ws_sold_date_sk = ci.c_first_sales_date_sk
WHERE ci.rank = 1 
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    pi.total_quantity, 
    id.i_item_desc, 
    id.i_current_price, 
    ci.rank
ORDER BY 
    total_quantity DESC,
    ci.c_last_name,
    ci.c_first_name;
