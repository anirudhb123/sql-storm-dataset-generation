
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS profit_rank
    FROM
        web_sales
    WHERE
        ws_ship_date_sk BETWEEN 1500 AND 2000
),
filtered_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        ranked_sales
    WHERE
        profit_rank = 1
    GROUP BY
        ws_item_sk
),
address_count AS (
    SELECT
        ca_address_sk,
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM
        customer_address
        LEFT JOIN customer ON ca_address_sk = c_current_addr_sk
    GROUP BY
        ca_address_sk, ca_city
),
final_report AS (
    SELECT
        f.ws_item_sk,
        f.total_quantity,
        f.avg_sales_price,
        f.total_net_profit,
        a.ca_city,
        a.customer_count
    FROM
        filtered_sales f
    LEFT JOIN address_count a ON f.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales)
)
SELECT
    fr.ws_item_sk,
    fr.total_quantity,
    fr.avg_sales_price,
    fr.total_net_profit,
    COALESCE(fr.ca_city, 'Unknown') AS city,
    COALESCE(fr.customer_count, 0) AS customer_count
FROM
    final_report fr
ORDER BY
    fr.total_net_profit DESC
LIMIT 50
UNION ALL
SELECT
    NULL AS ws_item_sk,
    SUM(ws_quantity) AS total_quantity,
    AVG(ws_sales_price) AS avg_sales_price,
    SUM(ws_net_profit) AS total_net_profit,
    'Total' AS city,
    COUNT(DISTINCT c_customer_sk) AS customer_count
FROM
    web_sales
    LEFT JOIN customer ON c_customer_sk = ws_bill_customer_sk
WHERE
    ws_ship_date_sk BETWEEN 1500 AND 2000;
