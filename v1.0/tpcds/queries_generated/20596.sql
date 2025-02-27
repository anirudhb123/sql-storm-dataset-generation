
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM
        web_sales ws
), CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
), AddressSales AS (
    SELECT
        ca.ca_address_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS net_profit
    FROM
        customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        ca.ca_address_sk
), HighValueOrders AS (
    SELECT
        sr_ticket_number,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM
        store_returns
    WHERE
        sr_return_quantity > 0
    GROUP BY
        sr_ticket_number
    HAVING
        total_return_value > 1000
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    rs.ws_item_sk,
    rws.total_sales,
    ch.total_orders,
    ch.net_profit,
    COALESCE(hvo.total_return_value, 0) AS high_value_return
FROM
    customer c
JOIN CustomerSales rws ON c.c_customer_sk = rws.c_customer_sk
JOIN AddressSales ch ON ch.ca_address_sk = c.c_current_addr_sk
JOIN RankedSales rs ON rs.ws_item_sk IN (
    SELECT ws_item_sk FROM RankedSales WHERE rnk <= 5
)
LEFT JOIN HighValueOrders hvo ON hvo.sr_ticket_number IN (
    SELECT sr_ticket_number FROM HighValueOrders
    EXCEPT
    SELECT ws_order_number FROM web_sales WHERE ws_ship_date_sk IS NULL
);
