
WITH ranked_customers AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_addresses AS (
    SELECT
        ca.*,
        CASE 
            WHEN ca.ca_city IS NOT NULL THEN ca.ca_city 
            ELSE 'Unknown' 
        END AS city_name,
        COALESCE(ca.ca_state, 'ZZ') AS state_code
    FROM
        customer_address ca
),
item_sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
),
combined_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        COALESCE(cs.cs_net_paid, 0) AS catalog_net_paid,
        COALESCE(rs.total_quantity, 0) AS web_total_quantity,
        COALESCE(hs.total_quantity, 0) AS store_total_quantity
    FROM
        store_sales ss
    LEFT JOIN
        catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk
    LEFT JOIN
        item_sales rs ON ss.ss_item_sk = rs.ws_item_sk
    LEFT JOIN (
        SELECT 
            cs_item_sk, 
            SUM(cs_quantity) AS total_quantity
        FROM 
            catalog_sales
        GROUP BY 
            cs_item_sk
    ) hs ON ss.ss_item_sk = hs.cs_item_sk
)
SELECT
    c.c_customer_id,
    coalesce(ca.city_name, 'Not Available') AS city_name,
    SUM(cs.total_net_paid) AS total_spent,
    COUNT(cs.ss_ticket_number) AS total_purchases
FROM
    ranked_customers rc
JOIN
    customer_addresses ca ON rc.c_customer_id = ca.ca_address_id
LEFT JOIN
    combined_sales cs ON rc.c_customer_id = cs.ss_ticket_number
WHERE
    rc.rank = 1
    AND ca.state_code <> 'ZZ'
    AND (rc.cd_marital_status = 'S' OR rc.cd_gender = 'F')
GROUP BY
    c.c_customer_id, ca.city_name
HAVING 
    SUM(cs.total_net_paid) > 1000
ORDER BY
    total_spent DESC
LIMIT 100
OFFSET 10;
