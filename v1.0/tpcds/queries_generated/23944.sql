
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
),
active_items AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_sold,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM
        item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    WHERE
        (ws.ws_sold_date_sk > 0 OR ss.ss_sold_date_sk > 0)
    GROUP BY
        i.i_item_sk, i.i_product_name, i.i_current_price
    HAVING
        SUM(COALESCE(ws.ws_quantity, 0)) > 100
),
recent_shipments AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(DISTINCT ws.ws_order_number) AS shipment_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        ws.ws_sold_date_sk = (
            SELECT MAX(ws2.ws_sold_date_sk) 
            FROM web_sales ws2) 
    GROUP BY
        sm.sm_ship_mode_id
),
customer_address_summary AS (
    SELECT
        c.c_customer_sk,
        a.ca_city,
        COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
        AVG(COALESCE(sr.sr_return_amt, 0)) AS average_return_amt
    FROM
        customer_info c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    GROUP BY
        c.c_customer_sk, a.ca_city
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.c_birth_year,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.i_product_name,
    ai.i_current_price,
    ai.total_sold,
    ai.order_count,
    cai.ca_city,
    cai.returns_count,
    cai.average_return_amt,
    rs.shipment_count,
    rs.total_profit
FROM
    customer_info ci
JOIN active_items ai ON ci.c_customer_sk IN (
    SELECT c.c_customer_sk FROM customer c
    WHERE c.c_current_cdemo_sk IN (
        SELECT cd.cd_demo_sk FROM customer_demographics cd WHERE cd.cd_gender = ci.cd_gender
    )
)
JOIN customer_address_summary cai ON ci.c_customer_sk = cai.c_customer_sk
LEFT JOIN recent_shipments rs ON rs.sm_ship_mode_id IN (
    SELECT sm.sm_ship_mode_id FROM ship_mode sm
    WHERE sm.sm_carrier LIKE '%Express%'
)
WHERE
    ci.gender_rank <= 10
ORDER BY
    ci.c_first_name, ai.total_sold DESC, cai.returns_count DESC
FETCH FIRST 100 ROWS ONLY;
