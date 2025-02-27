
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price IS NOT NULL
),
InventoryCheck AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
    HAVING
        SUM(inv.inv_quantity_on_hand) > 0
),
CustomerReturns AS (
    SELECT
        sr_sr.customer_sk,
        COUNT(*) AS return_count,
        SUM(sr.refunded_cash) AS total_refund
    FROM
        (
            SELECT sr_returning_customer_sk AS customer_sk FROM store_returns
            UNION ALL
            SELECT wr_returning_customer_sk FROM web_returns
        ) sr
    LEFT JOIN store_returns sr ON sr.sr_returning_customer_sk = sr.customer_sk
    LEFT JOIN web_returns wr ON wr.wr_returning_customer_sk = sr.customer_sk
    GROUP BY
        customer_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(CASE WHEN cr.return_count > 0 THEN cr.return_count ELSE 0 END) AS total_returns,
    MAX(cs.cs_ext_list_price) AS max_list_price,
    COALESCE(SUM(ic.total_quantity_on_hand), 0) AS total_inventory
FROM
    customer_address ca
JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
JOIN catalog_sales cs ON cs.cs_order_number = ss.ss_ticket_number
JOIN RankedSales rs ON rs.ws_item_sk = ss.ss_item_sk
LEFT JOIN InventoryCheck ic ON ic.inv_item_sk = ss.ss_item_sk
LEFT JOIN CustomerReturns cr ON cr.customer_sk = c.c_customer_sk
WHERE
    ca.ca_state IN ('CA', 'TX', 'NY')
    AND (rs.rn = 1 OR rs.rn = 2)
    AND ca.ca_zip IS NOT NULL
    AND (cs.cs_net_paid > 100 OR cs.cs_net_profit IS NOT NULL)
GROUP BY
    ca.ca_city, ca.ca_state
HAVING
    SUM(ws.ws_sales_price) > 5000
ORDER BY
    total_net_profit DESC, ca.ca_city;
