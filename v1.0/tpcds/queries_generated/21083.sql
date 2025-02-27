
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL

    UNION ALL

    SELECT ca.ca_address_sk, 
           CONCAT(ca.ca_street_name, ' - Level ', ah.level + 1) AS ca_street_name,
           ca.ca_city, 
           ca.ca_state, 
           ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_city = ah.ca_city AND ca.ca_state <> ah.ca_state
    WHERE ah.level < 5
),
purchase_summary AS (
    SELECT 
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sales_price > 0
    GROUP BY cd.cd_gender
),
return_summary AS (
    SELECT 
        wr_product_summary.item_id,
        SUM(wr.return_quantity) AS total_returns,
        COUNT(DISTINCT wr.return_order_number) AS return_count
    FROM web_returns wr
    JOIN (
        SELECT wr_item_sk AS item_id, COUNT(wr_order_number) AS order_count
        FROM web_returns
        GROUP BY wr_item_sk
    ) wr_product_summary ON wr.wr_item_sk = wr_product_summary.item_id
    WHERE wr.return_quantity IS NOT NULL
    GROUP BY wr_product_summary.item_id
),
final_summary AS (
    SELECT 
        ah.ca_city,
        ah.ca_state,
        ps.cd_gender,
        ps.total_spent,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (ps.total_spent - COALESCE(rs.total_returns, 0)) AS net_spent
    FROM address_hierarchy ah
    LEFT JOIN purchase_summary ps ON 1=1
    LEFT JOIN return_summary rs ON ps.customer_count > 0
    WHERE ah.level = 3 AND ah.ca_city IS NOT NULL
)
SELECT 
    jsonb_build_object(
        'city', ca_city,
        'state', ca_state,
        'gender', cd_gender,
        'total_spent', total_spent,
        'total_returns', total_returns,
        'net_spent', net_spent
    ) AS summary
FROM final_summary
WHERE net_spent > (SELECT AVG(total_spent) FROM purchase_summary)
ORDER BY net_spent DESC
LIMIT 100;
