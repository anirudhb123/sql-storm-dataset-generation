
WITH RECURSIVE sales_rank AS (
    SELECT 
        ws_bill_customer_sk, 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_item_sk
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city, 
        ca.ca_state,
        COUNT(DISTINCT cd_demo_sk) AS num_demographics,
        SUM(ws_net_profit) AS total_customer_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, ca.ca_city, ca.ca_state
), 
profitable_items AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS return_count
    FROM web_returns
    GROUP BY wr_item_sk
    HAVING COUNT(wr_return_quantity) > 5
),
date_range AS (
    SELECT d_date_sk 
    FROM date_dim 
    WHERE d_date BETWEEN '2021-01-01' AND '2021-12-31'
),
shipping_modes AS (
    SELECT sm.sm_ship_mode_sk, sm.sm_type
    FROM ship_mode sm
    WHERE sm.sm_code LIKE 'SH%'
)
SELECT 
    cs.c_customer_sk,
    cs.ca_city,
    cs.ca_state,
    cs.total_customer_profit,
    (CASE 
        WHEN cs.total_customer_profit IS NULL THEN 'No Sales'
        ELSE (SELECT COUNT(*) FROM sales_rank sr WHERE sr.ws_bill_customer_sk = cs.c_customer_sk)
     END) AS number_of_ranks,
    i.i_item_id,
    i.i_product_name,
    MAX(SUM(s.ws_net_profit)) OVER (PARTITION BY cs.c_customer_sk) AS max_profit_per_customer,
    s_sm.sm_type,
    COALESCE(ri.return_count, 0) AS returns_count
FROM customer_summary cs
JOIN date_range d ON d.d_date_sk IN (SELECT ws_sold_date_sk FROM web_sales)
JOIN shipping_modes s_sm ON EXISTS (SELECT 1 FROM web_sales ws WHERE ws.ws_ship_mode_sk = s_sm.sm_ship_mode_sk AND ws.ws_bill_customer_sk = cs.c_customer_sk)
LEFT JOIN profitable_items ri ON ri.wr_item_sk = cs.c_customer_sk 
JOIN item i ON i.i_item_sk = ri.wr_item_sk 
GROUP BY cs.c_customer_sk, cs.ca_city, cs.ca_state, cs.total_customer_profit, i.i_item_id, i.i_product_name, s_sm.sm_type, ri.return_count
ORDER BY total_customer_profit DESC, number_of_ranks DESC;
