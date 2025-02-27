
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL 
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_paid,
        CASE 
            WHEN rs.total_net_paid > 1000 THEN 'High Value'
            WHEN rs.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_sales <= 10
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ca.ca_city,
    ti.total_quantity,
    ti.total_net_paid,
    ti.value_category
FROM 
    customer ci
JOIN 
    customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    (SELECT 
         ws_item_sk,
         SUM(total_quantity) AS total_quantity,
         SUM(total_net_paid) AS total_net_paid,
         MAX(value_category) AS value_category
     FROM 
         TopItems
     GROUP BY 
         ws_item_sk) ti ON ti.ws_item_sk IN (
        SELECT 
            DISTINCT ws_item_sk 
        FROM 
            store_sales 
        WHERE 
            ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    )
WHERE 
    ca.ca_state NOT IN ('CA', 'NY') 
    AND (ci.c_birth_year IS NULL OR ci.c_birth_year > 1990)
ORDER BY 
    ti.total_net_paid DESC, ci.c_last_name ASC
FETCH FIRST 50 ROWS ONLY;
