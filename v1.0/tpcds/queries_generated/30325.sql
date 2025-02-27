
WITH RECURSIVE SalesRank AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 30
),
HighValueSellers AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_ship_date_sk IS NOT NULL
    GROUP BY ws_item_sk
    HAVING SUM(ws_sales_price) > 1000
),
CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_paid_inc_tax) AS total_spend
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk
),
StoreInventory AS (
    SELECT 
        i.i_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM item i
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_sk
)
SELECT 
    c.c_customer_id,
    cs.total_spend,
    COALESCE(sr.rank, 0) AS sales_rank,
    COALESCE(si.total_inventory, 0) AS inventory_count
FROM CustomerSpend cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN SalesRank sr ON cs.order_count = sr.rank
LEFT JOIN StoreInventory si ON si.i_item_sk = ANY(ARRAY(SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk))
WHERE cs.total_spend > 500
ORDER BY cs.total_spend DESC, c.c_customer_id
LIMIT 100
