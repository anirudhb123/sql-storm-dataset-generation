
WITH CustomerReturns AS (
    SELECT
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned_quantity,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_id
),
ActiveInventories AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
),
Comparison AS (
    SELECT
        c.c_customer_id,
        cr.total_returned_quantity,
        sd.total_sales_quantity,
        sd.total_sales_value,
        CASE 
            WHEN sd.total_sales_quantity > 0 THEN (cr.total_returned_quantity * 1.0 / sd.total_sales_quantity)
            ELSE NULL
        END AS return_rate
    FROM
        CustomerReturns cr
    JOIN SalesData sd ON cr.c_customer_id = sd.ws_item_sk
    JOIN customer c ON c.c_customer_id = cr.c_customer_id
),
RankedReturns AS (
    SELECT
        *,
        RANK() OVER (ORDER BY return_rate DESC) AS return_rate_rank
    FROM
        Comparison
)
SELECT
    c.c_customer_id,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(sd.total_sales_value, 0) AS total_sales_value,
    COALESCE(return_rate, 0) AS return_rate,
    return_rate_rank
FROM
    RankedReturns rr
JOIN customer c ON c.c_customer_id = rr.c_customer_id
LEFT JOIN ActiveInventories ai ON ai.inv_item_sk = rr.total_sales_quantity
WHERE
    (return_rate > 0 OR total_returned_quantity > 0)
    AND c.c_current_addr_sk IS NOT NULL
ORDER BY
    return_rate DESC
LIMIT 100;
