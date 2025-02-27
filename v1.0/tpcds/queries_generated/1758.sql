
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM web_sales
    WHERE ws_sales_price > 0
),
CustomerCounts AS (
    SELECT
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    JOIN customer ON ws_bill_customer_sk = c_customer_sk
    GROUP BY c_customer_sk
),
HighValueSales AS (
    SELECT
        cs_item_sk,
        SUM(cs_net_paid) AS total_net_paid
    FROM catalog_sales
    GROUP BY cs_item_sk
    HAVING SUM(cs_net_paid) > 1000
),
ReturnStats AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_item_sk
    HAVING SUM(cr_return_quantity) > 5
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(c.order_count, 0) AS customer_order_count,
    COALESCE(r.total_return_quantity, 0) AS return_quantity,
    COALESCE(r.total_return_amount, 0) AS return_amount,
    rs.rank,
    hp.total_net_paid
FROM item i
LEFT JOIN CustomerCounts c ON c.c_customer_sk = i.i_item_sk
LEFT JOIN ReturnStats r ON r.cr_item_sk = i.i_item_sk
LEFT JOIN RankedSales rs ON rs.ws_item_sk = i.i_item_sk AND rs.ws_order_number = (SELECT MAX(ws_order_number) FROM web_sales WHERE ws_item_sk = i.i_item_sk)
LEFT JOIN HighValueSales hp ON hp.cs_item_sk = i.i_item_sk
WHERE i.i_current_price IS NOT NULL
ORDER BY i.i_item_id ASC, return_amount DESC, customer_order_count DESC;
