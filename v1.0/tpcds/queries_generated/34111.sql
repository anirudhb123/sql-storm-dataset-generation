
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.customer_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        1 AS return_level
    FROM store_returns sr
    WHERE sr.returned_date_sk IS NOT NULL

    UNION ALL

    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.customer_sk,
        sr.return_quantity + cr.return_quantity,
        sr.return_amt + cr.return_amt,
        sr.return_tax + cr.return_tax,
        cr.return_level + 1
    FROM store_returns sr
    INNER JOIN CustomerReturns cr ON sr.customer_sk = cr.customer_sk AND sr.returned_date_sk = cr.returned_date_sk
    WHERE cr.return_level < 3
),
OrderStats AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
),
AddressInfo AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(d_date_sk) AS total_returns
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.customer_sk
    GROUP BY c.c_customer_sk, ca.ca_city, ca.ca_state
)
SELECT 
    ai.c_customer_sk,
    ai.ca_city,
    ai.ca_state,
    ai.total_returns,
    os.total_profit,
    os.total_orders,
    os.avg_profit
FROM AddressInfo ai
LEFT JOIN OrderStats os ON ai.c_customer_sk = os.bill_customer_sk
WHERE ai.total_returns > 0
ORDER BY total_returns DESC, os.total_profit DESC
FETCH FIRST 100 ROWS ONLY;
