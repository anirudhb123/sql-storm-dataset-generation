
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_net_paid, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
),
total_returns AS (
    SELECT 
        cr.cr_item_sk, 
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr 
    GROUP BY cr.cr_item_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown' 
            ELSE cd.cd_credit_rating 
        END AS credit_rating 
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk, 
        CONCAT_WS(' ', 
            COALESCE(ca.ca_street_number, 'N/A'), 
            COALESCE(ca.ca_street_name, ''), 
            COALESCE(ca.ca_street_type, ''), 
            COALESCE(ca.ca_suite_number, '')) AS full_address
    FROM customer_address ca
)
SELECT 
    cs.c_customer_sk, 
    cs.credit_rating, 
    cs.cd_gender,
    COALESCE(rt.total_return_qty, 0) AS total_return_qty,
    COALESCE(rt.total_return_amount, 0) AS total_return_amount,
    CONCAT_WS(',', cs.full_address) AS customer_address,
    MAX(sales.ws_net_paid) AS max_net_paid
FROM customer_details cs
LEFT JOIN total_returns rt ON cs.c_customer_sk = rt.cr_item_sk
LEFT JOIN address_info addr ON cs.c_current_addr_sk = addr.ca_address_sk
LEFT JOIN ranked_sales sales ON sales.ws_item_sk = rt.cr_item_sk AND sales.rn = 1
GROUP BY cs.c_customer_sk, cs.credit_rating, cs.cd_gender, cs.full_address
HAVING MAX(sales.ws_net_paid) > (SELECT AVG(ws.ws_net_paid) FROM web_sales ws WHERE ws.ws_ship_date_sk IS NOT NULL) 
   AND cs.cd_marital_status IS NOT NULL 
ORDER BY total_return_qty DESC, cs.cd_gender DESC NULLS LAST;
