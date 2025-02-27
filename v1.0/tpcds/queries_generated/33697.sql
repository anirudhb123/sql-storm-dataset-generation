
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
cum_profit AS (
    SELECT
        ss.ws_item_sk,
        SUM(ss.total_profit) OVER (PARTITION BY ss.ws_item_sk ORDER BY ss.ws_sold_date_sk) AS cumulative_profit
    FROM
        sales_summary ss
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    ca.ca_city,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    MAX(ws.ws_net_profit) AS max_net_profit,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = i.i_item_sk) AS total_returns,
    (CASE 
        WHEN COUNT(DISTINCT ws.ws_order_number) > 0 THEN SUM(ws.ws_net_profit) / COUNT(DISTINCT ws.ws_order_number)
        ELSE 0
    END) AS avg_profit_per_order
FROM
    item i
JOIN
    web_sales ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN
    customer_address ca ON ca.ca_address_sk = (
        SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = ws.ws_bill_customer_sk
    )
LEFT JOIN
    cum_profit cp ON cp.ws_item_sk = ws.ws_item_sk
WHERE
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2021) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
GROUP BY
    i.i_item_id,
    i.i_item_desc,
    ca.ca_city
HAVING
    SUM(ws.ws_net_profit) > 1000
ORDER BY
    total_quantity_sold DESC
LIMIT 10;
