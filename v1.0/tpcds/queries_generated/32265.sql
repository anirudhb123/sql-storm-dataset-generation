
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_desc, i_brand, 1 AS level
    FROM item
    WHERE i_item_id = 'ITEM0001'  -- Starting point

    UNION ALL

    SELECT i.i_item_sk, i.i_item_desc, i.i_brand, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk  -- Assumed relationship
    WHERE ih.level < 5  -- Limiting levels for recursion
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2022
    GROUP BY ws.ws_item_sk, d.d_year
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_profit DESC) AS overall_rank
    FROM SalesData sd
    WHERE sd.rnk <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
FilteredCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM CustomerSales cs
    WHERE cs.total_spent > 500
)
SELECT 
    ih.i_item_desc,
    ih.i_brand,
    ts.total_quantity,
    ts.total_profit,
    fc.c_first_name,
    fc.c_last_name,
    fc.total_spent
FROM ItemHierarchy ih
JOIN TopSales ts ON ih.i_item_sk = ts.ws_item_sk
JOIN FilteredCustomers fc ON fc.total_orders > 5
ORDER BY ts.total_profit DESC, fc.total_spent DESC
LIMIT 50;
