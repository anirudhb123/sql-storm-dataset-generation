
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, 1 AS hierarchy_level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.hierarchy_level < 5
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_revenue,
        AVG(ws.ws_net_profit) AS average_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
CustomerReturnData AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(DISTINCT cr.cr_order_number) AS total_returns,
        SUM(cr.cr_return_amt) AS total_returned_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
CombinedSales AS (
    SELECT
        sd.ws_item_sk,
        COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(sd.total_revenue, 0) AS total_revenue,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_returned_amount, 0) AS total_returned_amount,
        (COALESCE(sd.total_revenue, 0) - COALESCE(rd.total_returned_amount, 0)) AS net_revenue
    FROM SalesData sd
    LEFT JOIN CustomerReturnData rd ON sd.ws_item_sk = rd.cr_item_sk
),
QualifiedCustomers AS (
    SELECT 
        ch.c_customer_sk, 
        ch.c_first_name, 
        ch.c_last_name, 
        sa.ws_item_sk,
        sa.net_revenue,
        ROW_NUMBER() OVER (PARTITION BY ch.c_customer_sk ORDER BY sa.net_revenue DESC) AS rn
    FROM CustomerHierarchy ch
    JOIN CombinedSales sa ON ch.c_current_addr_sk IN (
        SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_address_sk = ch.c_current_addr_sk
    )
)
SELECT 
    qc.c_customer_sk,
    qc.c_first_name,
    qc.c_last_name,
    cs.ws_item_sk,
    cs.net_revenue
FROM QualifiedCustomers qc
JOIN CombinedSales cs ON qc.ws_item_sk = cs.ws_item_sk
WHERE qc.rn <= 3
ORDER BY qc.c_customer_sk, cs.net_revenue DESC;
