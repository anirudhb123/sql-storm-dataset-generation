
WITH RECURSIVE ProductHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_class_id
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT p.i_item_sk, p.i_item_id, p.i_item_desc, p.i_current_price, p.i_class_id
    FROM item p
    JOIN ProductHierarchy ph ON p.i_class_id = ph.i_class_id
    WHERE p.i_current_price < ph.i_current_price
),
SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= 2459882  -- Assuming a specific date range
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT sd.ws_order_number) AS total_orders,
        SUM(sd.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_item_sk
    GROUP BY c.c_customer_sk
),
HighValueCustomers AS (
    SELECT c.c_customer_sk
    FROM CustomerSales c
    WHERE total_profit > 1000
)
SELECT 
    ph.i_item_id,
    ph.i_item_desc,
    ph.i_current_price,
    SUM(sd.ws_quantity) AS total_quantity_sold,
    SUM(sd.ws_net_paid) AS total_sales_revenue,
    COALESCE(SUM(CASE WHEN hvc.c_customer_sk IS NOT NULL THEN sd.ws_net_profit END), 0) AS high_value_customer_profit,
    ph.i_class_id
FROM ProductHierarchy ph
JOIN SalesData sd ON ph.i_item_sk = sd.ws_item_sk
LEFT JOIN HighValueCustomers hvc ON sd.ws_item_sk = hvc.c_customer_sk
GROUP BY ph.i_item_id, ph.i_item_desc, ph.i_current_price, ph.i_class_id
HAVING SUM(sd.ws_quantity) > 100
ORDER BY total_sales_revenue DESC
LIMIT 10;
