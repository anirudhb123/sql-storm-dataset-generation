
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_name, ca_city, ca_county, ca_state
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_street_name, ca.ca_city, ca.ca_county, ca.ca_state
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_city = ah.ca_city AND ca.ca_county <> ah.ca_county
), ranked_customers AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as purchase_rank,
        ca.ca_city 
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
), customer_summary AS (
    SELECT 
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        COUNT(DISTINCT w.ws_order_number) AS order_count,
        SUM(w.ws_net_profit) AS total_profit,
        MAX(w.ws_net_paid_inc_tax) AS max_payment
    FROM ranked_customers rc
    LEFT JOIN web_sales w ON rc.c_customer_id = w.ws_bill_customer_sk
    GROUP BY rc.c_customer_id, rc.cd_gender, rc.cd_marital_status
), null_check AS (
    SELECT 
        cu.c_customer_id, 
        cu.order_count, 
        cu.total_profit,
        COALESCE(ca.ca_state, 'Unknown') AS address_state
    FROM customer_summary cu
    LEFT JOIN customer_address ca ON cu.c_customer_id = ca.ca_address_sk
), final_selection AS (
    SELECT
        n.c_customer_id,
        n.order_count,
        n.total_profit,
        n.address_state,
        ROW_NUMBER() OVER (ORDER BY n.total_profit DESC) AS rank
    FROM null_check n
    WHERE n.total_profit IS NOT NULL AND n.order_count >= 10
)

SELECT 
    f.c_customer_id,
    f.order_count,
    f.total_profit,
    f.address_state,
    CASE 
        WHEN f.total_profit > 5000 THEN 'High Value'
        WHEN f.total_profit BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM final_selection f
WHERE f.rank <= 100
AND f.address_state NOT LIKE 'Unknown%'
ORDER BY f.total_profit DESC;
