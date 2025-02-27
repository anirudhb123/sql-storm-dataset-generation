
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_profit
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk IN (
            SELECT DISTINCT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_moy BETWEEN 6 AND 8
        )
),
Returns AS (
    SELECT
        sr_cr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM
        store_returns
    GROUP BY
        sr_returned_item_sk
),
Combined AS (
    SELECT
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        COALESCE(r.total_returned_quantity, 0) AS returned_quantity,
        CASE
            WHEN rs.rn = 1 THEN 'Best Seller'
            ELSE 'Regular Seller'
        END AS classification
    FROM
        RankedSales rs
    LEFT JOIN Returns r ON rs.ws_item_sk = r.sr_cr_item_sk
    WHERE
        total_profit > (SELECT AVG(total_profit) FROM RankedSales)
)
SELECT
    ca.ca_city,
    ca.ca_state,
    SUM(cs.cs_net_profit) AS total_net_profit
FROM
    Combined c
JOIN
    catalog_sales cs ON c.ws_item_sk = cs.cs_item_sk
JOIN
    customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE
    c.returned_quantity < c.ws_quantity AND
    ca.ca_state IS NOT NULL
GROUP BY
    ca.ca_city, ca.ca_state
HAVING
    SUM(cs.cs_net_profit) > 1000
ORDER BY
    total_net_profit DESC
LIMIT 10;
