
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn,
        ws.ws_net_profit,
        DENSE_RANK() OVER(ORDER BY ws.ws_ship_date_sk) AS ship_rank
    FROM web_sales ws
    WHERE ws.ws_net_profit IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender, 
        ci.cd_marital_status, 
        ci.cd_purchase_estimate, 
        ci.ca_state,
        COUNT(DISTINCT r.sr_ticket_number) AS return_count,
        SUM(COALESCE(r.sr_return_amt, 0) - COALESCE(r.sr_return_tax, 0)) AS total_refunded_amount
    FROM customer_info ci
    LEFT JOIN store_returns r ON ci.c_customer_id = r.sr_customer_sk
    WHERE ci.cd_purchase_estimate > 1000
    GROUP BY ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ci.cd_purchase_estimate, ci.ca_state
),
aggregated_returns AS (
    SELECT 
        hv.ca_state,
        SUM(hv.total_refunded_amount) AS total_refunds,
        AVG(hv.return_count) AS avg_returns
    FROM high_value_customers hv
    GROUP BY hv.ca_state
)
SELECT 
    a.ca_state,
    a.total_refunds,
    a.avg_returns,
    SUM(r.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT r.ws_order_number) AS order_count,
    CASE 
        WHEN a.total_refunds IS NULL THEN 'No Refunds'
        WHEN a.avg_returns > 5 THEN 'High Return Rate'
        ELSE 'Normal'
    END AS return_category
FROM aggregated_returns a
LEFT JOIN ranked_sales r ON a.ca_state = 
    (SELECT DISTINCT ca.ca_state FROM customer_address ca WHERE ca.ca_address_sk IN (SELECT c.c_current_addr_sk FROM customer c))
GROUP BY a.ca_state, a.total_refunds, a.avg_returns
ORDER BY a.total_refunds DESC, a.avg_returns ASC;
