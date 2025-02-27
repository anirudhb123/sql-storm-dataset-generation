
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sale_rank,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS num_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), 
empty_sales AS (
    SELECT DISTINCT 
        i_item_id,
        COUNT(DISTINCT ws_order_number) AS total_sales_count
    FROM item i 
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i_item_id
    HAVING COUNT(ws_order_number) = 0
),
customer_quality AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating 
        END AS credit_quality,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_credit_rating
    HAVING COUNT(DISTINCT cs.cs_order_number) > 10
)
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    c.c_customer_id,
    SUM(ws.ws_net_profit) AS total_web_profit,
    (SELECT AVG(ws_ext_discount_amt) 
     FROM web_sales 
     WHERE ws_sold_date_sk BETWEEN 20250101 AND 20270101 
     AND ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 100)
    ) AS avg_discount_large_items,
    CASE 
        WHEN COUNT(DISTINCT ws.ws_order_number) > 5 AND MAX(ws.ws_net_profit) IS NOT NULL 
        THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value,
    COALESCE((
       SELECT COUNT(*) 
       FROM empty_sales es 
       WHERE es.total_sales_count = 0 
       AND es.i_item_id IN (SELECT i_item_id FROM ranked_sales rs WHERE rs.sale_rank <= 5)
    ), 0) AS empty_sales_count,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_quality cq ON c.c_customer_id = cq.c_customer_id
WHERE ws.ws_sold_date_sk = (
    SELECT MAX(ws_inner.ws_sold_date_sk) 
    FROM web_sales ws_inner 
    WHERE ws_inner.ws_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand < 100)
)
GROUP BY ca.ca_city, ca.ca_state, c.c_customer_id
HAVING SUM(ws.ws_net_profit) > (
    SELECT AVG(total_net_profit) FROM ranked_sales
)
ORDER BY profit_rank, ca.ca_city;
